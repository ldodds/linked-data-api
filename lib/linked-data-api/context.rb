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
    
    #TODO This should return completely bound variables, suitable for injecting into SPARQL query
    #will involve altering based on type
    def sparql_variables
      if @vars == nil
        #TODO need to include variables from current endpoint and those inherited from API
        query_vars = {}
        request.params.each do |k,v|
          p = @terms[k]          
          query_vars[k] = LinkedDataAPI::SPARQLUtil.sparql_value(v) if p == nil
          query_vars[k] = p.to_sparql(v) if p != nil
        end
        @vars = query_vars        
      end
      return @vars
    end
       
  end
  
end