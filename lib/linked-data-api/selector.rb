module LinkedDataAPI

  #TODO introduce a factory object for generating unique variables names to avoid clashes
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
      "exists" => "FILTER ( !bound(?obj) ).\n", 
      "name" => "?obj <http://www.w3.org/2000/01/rdf-schema#label> ?val.\n"
    }
    
    def initialize(parent=nil)
      @parent = parent
      yield self if block_given?
    end
    
    #create the select query to select the item
    #the hash is of prefix -> uri
    def select_query(context)
      prefixes = LinkedDataAPI::SPARQLUtil.namespaces_to_sparql_prefix(context.namespaces)
      #select specified in url
      if context.request.params["_select"] != nil
        return prefixes + context.request.params["_select"]          
      end
      #select specified in configuration      
      if @select != nil && context.request.params["_select"] == nil
        #TODO generate warning if there's a parent with selection properties (select,where,filter)
        return prefixes + @select
      end
      
      graph_pattern = create_graph_pattern(context)      
      order_by = create_order_by(context)
      paging = create_paging(context)
      query = prefixes + "SELECT ?item WHERE {\n#{graph_pattern}}"
      query = query + "\n#{order_by}" unless order_by == ""
      query = query + "\n#{paging}"
        
      #bind any remaining variables
      #TODO this is only unreserved_params what about the others?      
      query = Pho::Sparql::SparqlHelper.apply_initial_bindings(query, context.unreserved_params)
      
      return query
      
    end
        
    def create_paging(context)
      page_size = context.page_size
      offset = nil
      page_num = context.request.params["_page"]
      if page_num != nil && page_num.to_i > 1
        offset = (page_size * (page_num.to_i -1) ) + 1
      end
      return "LIMIT #{page_size}" if offset == nil
      return "LIMIT #{page_size} OFFSET #{offset}"
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
        pattern = pattern + "." unless context.request.params["_where"].end_with?(".")     
      end      
      if @where != nil && context.request.params["_where"] == nil        
        pattern = pattern + @where
        pattern = pattern + "." unless @where.end_with?(".") 
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
              pattern = add_to_pattern(pattern, context, name, value, :variables)           
            end                        
          end
        end

        #if we have no api:filter and haven't inherited a pattern
        #use this default, as declared in the specification
        if @filter == nil && pattern == ""
          pattern = "?item ?property ?value.\n"        
        end
                
      end
      pattern = add_graph_pattern_for_sorting(context, pattern)
      return pattern
    end

    #Extend the provided graph pattern to add additional patterns, if required to handle sort conditions
    def add_graph_pattern_for_sorting(context, pattern)       
       sortSpec, sparql = sort_specification(context)
       return pattern if sortSpec == nil
       #puts sortSpec, sparql
       if sparql
         return pattern         
       else
         properties = sortSpec.split(",")         
         properties.each do |prop|     
           prop.sub!("-", "")
           varName = "?sort_#{prop.sub(".", "_")}"
           #FIXME? don't redundantly add patterns if we've already got a specific test for this property
           #if !context.bare_param_names.include?(prop)
             pattern = add_to_pattern(pattern, context, prop, varName, :literal, false)
           #end           
         end
       end
       return pattern
    end
    
    #Return the sort spec. Return value is a an array: [sortSpec, true|false]. True if this is direct SPARQL OrderCondition 
    def sort_specification(context)
      if context.request.params["_orderBy"] != nil
        return context.request.params["_orderBy"], true
      end
      if context.request.params["_sort"] != nil
        return context.request.params["_sort"], false
      end
      if @order_by != nil
        return @order_by, true
      end
      return @sort, false
    end
    
    #Add any additional patterns required to support ordering
    #pattern:: current pattern being assembled
    #context:: the current execution context
    def create_order_by(context)
      sortSpec, sparql = sort_specification(context)
      return "" if sortSpec == nil
      if sparql
        return "ORDER BY " + sortSpec
      else
        clause = "ORDER BY "
        properties = sortSpec.split(",")
        properties.each do |prop|
          #FIXME
          varName = "?sort_#{prop.sub("-", "").sub(".", "_")}"
          #FIXME? don't redundantly add patterns if we've already got a specific test for this property
          #if !context.bare_param_names.include?(prop)
            if prop.start_with?("-")
              clause = clause + "DESC(#{varName}) "
            else
              clause = clause + "ASC(#{varName}) "
            end
            
          #end           
        end
        return clause
      end
    end
    
    #pattern:: the current pattern being assembled
    #context:: the current execution context
    #name:: name of the variable to add
    #value:: value of the variable to add
    #values:: :literal, :variables, :fixed is provided value to be included literally, are variables allowed in the specification of the value (true only for api:filter)
    def add_to_pattern(pattern, context, name, value, values=:fixed, fail_if_name_not_bound=false)      
      if name.include?(".")
        return add_property_path_to_pattern(pattern, context, name, value, values, fail_if_name_not_bound)
      end
      if name.include?("-") && FILTER_PREFIXES.keys.include?( name.split("-")[0] )
        return add_filter_pattern(pattern, context, name, value, values, fail_if_name_not_bound)
      end
      term = context.terms[name]
      #if we have a binding for the property then add it
      if term != nil
         val = create_value(context, term, value, values)
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

    def add_filter_pattern(pattern, context, name, value, values=:fixed, fail_if_name_not_bound=false)
       prefix = name.split("-")[0]
       propertyName = name.split("-")[1]
       safeName = name.sub("-", "_")
       term = context.terms[propertyName]
       val = create_value(context, term, value, values)
       if prefix == "exists"
         if value == "true"
           pattern = pattern + "?item <#{term.uri}> ?#{safeName}.\n"
         else
           pattern = pattern + "OPTIONAL { ?item <#{term.uri}> ?#{safeName}. } "
           template = FILTER_PREFIXES[prefix]
           pattern = pattern + template.sub("?obj", "?#{safeName}").sub("?val", val)             
         end
       else
         pattern = pattern + "?item <#{term.uri}> ?#{safeName}. "         
         template = FILTER_PREFIXES[prefix]
         pattern = pattern + template.sub("?obj", "?#{safeName}").sub("?val", val)           
       end
       return pattern
    end
    
    #foo.bar.baz=2   ?item <foo> [ <bar> [ <baz> "2" ] ]            
    def add_property_path_to_pattern(pattern, context, name, value, values=:fixed, fail_if_name_not_bound=false)
      pattern = pattern + "?item "
      path_elements = name.split(".")    
      path_elements.slice(0..-2).each do |path|
        #TODO what if term not bound?
        term = context.terms[path]
        pattern = pattern + "<#{term.uri}> [ " 
      end     
      #FIXME error checking
      last_term = context.terms[path_elements.last]
      val = create_value(context, last_term, value, values)
      pattern = pattern + "<#{last_term.uri}> #{val}."
      path_elements.slice(0..-2).size.times do
        pattern = pattern + " ].\n"
      end
      return pattern      
    end
    
    #context:: current context
    #term:: the term whose value we're creating
    #value:: the value, which may be a variable
    def create_value(context, term, value, values)
      #also check if value is mapped, i.e. for classes
      if context.terms[value] != nil
        return context.terms[value].to_sparql(value)
      else
        #Check whether the value is actually a named variable
        #if it is then add the value from the query string if available
        #TODO: need to support generic variables too...
        if values == :variables && value.match(/\{([^\/]+)\}/) != nil
          varName = value.match(/\{([^\/]+)\}/)[1]
          return term.to_sparql( context.unreserved_params[varName] )
        elsif values == :literal
          return value
        else
          return term.to_sparql(value)
        end
      end  
        
    end       
       
  end  
end