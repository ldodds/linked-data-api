module LinkedDataAPI

  #The execution context for request. Encapsulates access to the current request and assembly of 
  #parameter bindings
  class Context
    
    #A Rack::Request
    attr_accessor :request
    #Namespace bindings    
    attr_accessor :namespaces
    #Named RDF properties
    attr_accessor :terms
    #Currently executing endpoint
    attr_accessor :endpoint
    #Non-reserved query string parameters
    attr_reader :unreserved_params
    
    def Context.interpolate(h)
      interpolated = {}
      h.each do |k,v|        
        matched = v.match(/\{([^\/]+)\}/)
        if matched != nil
          interpolated[k] = h[matched[1]]
        else
          interpolated[k] = v  
        end
      end
      return interpolated
    end
    
    #TODO: properties and namespaces are being injected here, but could come from API?
    #Depends on whether we want to do schema loading 
    def initialize(request, endpoint, terms={}, namespaces={}) # :yield: self      
      @request = request
      @endpoint = endpoint
      @terms = terms
      @namespaces = namespaces      
      yield self if block_given?
      @unreserved_params = {}
      @request.params.each do |name,value|
        @unreserved_params[name] = value if !name.start_with?("_")
      end      
    end
    
    #return all current bound variables
    #Order of precedence:
    #Query String, URI Template, Endpoint, API
    def variables
      if @vars == nil
        @vars = {}
        @vars = @endpoint.variables unless @endpoint == nil
        #TODO ignores?
        @vars = @vars.merge( LinkedDataAPI::URLMatcher::extract(request.path, @endpoint.uri, request.params) ) unless @endpoint == nil        
        @vars = @vars.merge( request.params )
        @vars = Context.interpolate(@vars)       
      end
      return @vars
    end
    
    
    
    #This should return completely bound variables, suitable for injecting into SPARQL query
    #will involve altering based on type
    def sparql_variables
      sparql_vars = {}
      variables().each do |k,v|
        p = @terms[k]          
        sparql_vars[k] = LinkedDataAPI::SPARQLUtil.sparql_value(v) if p == nil
        sparql_vars[k] = p.to_sparql(v) if p != nil
      end
      return sparql_vars
    end
    
    def max_page_size()
     return @endpoint.max_page_size unless @endpoint == nil
     return nil 
    end
    
    #Return the page size based on information in the request and/or defaults from API configuration
    def page_size()      
      if @request.params["_pageSize"] != nil
        size = @request.params["_pageSize"].to_i
        if max_page_size == nil || (max_page_size() != nil && size <= max_page_size())
          return size
        end
        return max_page_size()
      end
      return @endpoint.default_page_size unless @endpoint == nil
      return 10 
    end   
  end
  
end