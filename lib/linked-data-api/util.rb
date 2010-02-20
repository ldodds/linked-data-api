module LinkedDataAPI
  
  module SPARQLUtil
  
    NUMBERS = ["int", "float"].map{ |n| "http://www.w3.org/2001/XMLSchema\##{n}"}
    
    #Take a hash of namespace prefix bindings and return SPARQL prefix declaration 
    def SPARQLUtil.namespaces_to_sparql_prefix(namespaces={})
            
      prefix = ""
      @bindings.sort.each do |binding|
        prefix = prefix + "PREFIX #{binding[0]}: <#{binding[1]}>\n"
      end
      return prefix        
    end

    def SPARQLUtil.sparql_value(value, range=nil)
      if range == nil || range == "http://www.w3.org/2001/XMLSchema#string"
        return "\"#{value}\""
      end
      if range == "http://www.w3.org/2000/01/rdf-schema#Resource"
        #FIXME uri validation?
        return "<#{value}>"
      end
      if NUMBERS.include?(range)
         #FIXME number validation?
         return value
      end      
      return "\"#{value}\"^^<#{range}>"            
    end    
  end
  
end