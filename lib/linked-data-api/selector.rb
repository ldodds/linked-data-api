module LinkedDataAPI

  class Selector
  
    attr_accessor :parent
    attr_accessor :select
    attr_accessor :where
    attr_accessor :order_by
    attr_accessor :filter
    attr_accessor :sort
    
    FILTER_PREFIXES = {
      "min" => "FILTER ( ?obj >= ?val ).\n", 
      "max" => "FILTER ( ?obj <= ?val ).\n", 
      "minEx" => "FILTER ( ?obj > ?val ).\n", 
      "maxEx" => "FILTER ( ?obj < ?val ).\n", 
      #FIXME resolve whether we need a FILTER for exists. And what about not exists?
      "exists" => "FILTER ( bound(?obj) ).\n", 
      "name" => "?obj <http://www.w3.org/2000/01/rdf-schema#label> ?val.\n"
    }
    
    def initialize(parent=nil)
      @parent = parent
      yield self if block_given?
    end
    
    #create the select query to select the item
    #the hash is of prefix -> uri
    def select_query(context, bind=true)
      prefixes = LinkedDataAPI::SPARQLUtil.namespaces_to_sparql_prefix(context.namespaces) + "\n"
      #select specified in url
      if context.request.params["_select"] != nil
        return prefixes + context.request.params["_select"]          
      end
      #select specified in configuration      
      if @select != nil && context.request.params["_select"] == nil
        #TODO generate warning if there's a parent with selection properties (select,where,filter)
        return prefixes + @select
      end
      
      query = prefixes + "SELECT ?item \nWHERE {\n #{create_graph_pattern(context)}\n}\n#{create_order_by(context)}\n#{create_paging(context)}"
      
      if bind
        query = Pho::Sparql::SparqlHelper.apply_initial_bindings(query, context.variables)
      end
      
      return query
      
    end
    
    def create_graph_pattern(context)
      pattern = ""
      #TODO generate warning if parent has select?
      if @parent != nil && @parent.select() == nil        
        pattern = @parent.create_graph_pattern(context)
      else
        pattern = ""
      end
      #_where is used in preference
      #if no _where and api:where then use that
      #otherwise we use api:filter
      if context.request.params["_where"] != nil
        pattern = pattern + context.request.params["_where"]
      end      
      if @where != nil && context.request.params["_where"] == nil
        pattern = pattern + @where
      end
      if @where == nil && context.request.params["_where"] == nil
        #construct patterns and filters
        
        #Add bound request parameters to pattern
        #Sort here is for some consistency when testing
        context.unreserved_params.sort.each do |entry|
          name = entry[0]
          value = entry[1]
          pattern = add_to_pattern(pattern, context, name, value)                 
        end
                
        #Add contents of the api:filter property if specified
        #Parameters specified here are only added if they're not in the query string
        if @filter != nil
          #the sort here adds some predictably for testing
          @filter.split("&").sort.each do |pair|
            name, value = pair.split("=")
            #Only process this name from api:filter if its not in the query string
            if context.unreserved_params[name] == nil
              pattern = add_to_pattern(pattern, context, name, value, true)           
            end                        
          end
        end

        #if we have no api:filter and haven't inherited a pattern
        #use this default, as declared in the specification
        if @filter == nil && pattern == ""
          pattern = "?item ?property ?value.\n"        
        end
                
      end
      return pattern
    end

    #pattern:: the current pattern being assembled
    #context:: the current execution context
    #name:: name of the variable to add
    #value:: value of the variable to add
    #vars_allowed:: are variables allowed in the specification of the value (true only for api:filter)
    def add_to_pattern(pattern, context, name, value, vars_allowed=false, fail_if_name_not_bound=false)      
      if name.include?(".")
        return add_property_path_to_pattern(pattern, context, name, value, vars_allowed, fail_if_name_not_bound)
      end
      if name.include?("-") && FILTER_PREFIXES.keys.include?( name.split("-")[0] )
        return add_filter_pattern(pattern, context, name, value, vars_allowed, fail_if_name_not_bound)
      end
      term = context.terms[name]
      #if we have a binding for the property then add it
      if term != nil
         val = create_value(context, term, value, vars_allowed)
         pattern = pattern + "?item <#{term.uri}> #{val}.\n" unless value == nil
      else        
        if fail_if_name_not_bound
          #FIXME throw exception
          raise
        else
          #TODO add a warning if we're handling an api:filter, as if a param in the filter isn't bound then the API config is wrong 
        end  
      end              
      return pattern                    
    end    

    def add_filter_pattern(pattern, context, name, value, vars_allowed=false, fail_if_name_not_bound=false)
       prefix = name.split("-")[0]
       name = name.split("-")[1]
       term = context.terms[name]
       val = create_value(context, term, value, vars_allowed)
       pattern = pattern + "?item <#{term.uri}> ?#{name}. "
       template = FILTER_PREFIXES[prefix]
       pattern = pattern + template.sub("?obj", "?#{name}").sub("?val", val)
       return pattern
    end
    
    #foo.bar.baz=2   ?item <foo> [ <bar> [ <baz> "2" ] ]            
    def add_property_path_to_pattern(pattern, context, name, value, vars_allowed=false, fail_if_name_not_bound=false)
      pattern = pattern + "?item "
      path_elements = name.split(".")    
      path_elements.slice(0..-2).each do |path|
        #TODO what if term not bound?
        term = context.terms[path]
        pattern = pattern + "<#{term.uri}> [ " 
      end     
      #FIXME error checking
      last_term = context.terms[path_elements.last]
      val = create_value(context, last_term, value, vars_allowed)
      pattern = pattern + "<#{last_term.uri}> #{val}."
      path_elements.slice(0..-2).size.times do
        pattern = pattern + " ].\n"
      end
      return pattern      
    end
    
    #context:: current context
    #term:: the term whose value we're creating
    #value:: the value, which may be a variable
    def create_value(context, term, value, vars_allowed)
      #also check if value is mapped, i.e. for classes
      if context.terms[value] != nil
        return context.terms[value].to_sparql(value)
      else
        #Check whether the value is actually a named variable
        #if it is then add the value from the query string if available
        #TODO: need to support generic variables too...
        if vars_allowed && value.match(/\{([^\/]+)\}/) != nil
          varName = value.match(/\{([^\/]+)\}/)[1]
          return term.to_sparql( context.unreserved_params[varName] )
        else
          return term.to_sparql(value)
        end
      end  
        
    end  
     
       
  end  
end