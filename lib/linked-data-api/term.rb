module LinkedDataAPI
   
  #An RDF property from the API configuration
  #Can be bound to a name
  class Term
          
    attr_reader :uri, :bound_name, :label, :range
    
    def Term.create_property(uri, bound_name, label=nil, range=nil)
      return Term.new(uri, bound_name, label, range)
    end
    
    def Term.create_class(uri, bound_name, label=nil)
      return Term.new(uri, bound_name, label, "http://www.w3.org/2000/01/rdf-schema#Resource", true)
    end
    
    def initialize(uri, bound_name, label, range=nil, cls=false)
      @uri = uri
      @bound_name = bound_name
      @label = label
      @range = range
      @cls = cls
    end

    #Has this property been explicitly bound to a name
    #true if there'a an api:label, false otherwise
    def bound?
      return bound_name != nil
    end
    
    def add_to_hash(hash)
      hash[self.name()] = self
    end
    
    #Retrieve the name of this property
    def name()
      if bound?
        return bound_name
      end
      if label && label.match(/[a-zA-Z][a-zA-Z0-9_]*/) != nil
        return label
      end
      return uri.split(/(\/|#)/).last
    end
    
    #Format the provided value to the appropriate form for adding to a SPARQL query
    def to_sparql(value)
      if @cls
        return LinkedDataAPI::SPARQLUtil.sparql_value(@uri, @range)
      end
      return LinkedDataAPI::SPARQLUtil.sparql_value(value, @range)   
    end
    
  end
 
end