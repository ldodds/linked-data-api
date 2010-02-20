module LinkedDataAPI
  
  #Intended to model variables declared in API and Endpoint
  class Variable
      attr_reader :name, :value, :range
      
      #type is nil by default, but can be a uri of a type, including rdf:Resource, rdfs:Property (rdfs:range or api:type) 
      def initialize(name, value, range=nil)
          @name = name
          @value = value
          @range = range
      end
      
      def to_sparql()
        return LinkedDataAPI::SPARQLUtil.sparql_value(@value, @range)
      end
  end
  
  
end  