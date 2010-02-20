module LinkedDataAPI
  
  #An API over a Linked Data source
  class API
    
    attr_accessor :sparql_endpoint, :base, :content_negotiation, :variables, :endpoints
    
    #Create an api for a specific sparql endpoint. Default content negotation type is based on suffix (:suffix). 
    #Alternate is :parameter
    def initialize(sparql_endpoint=nil, base=nil, content_negotiation=:suffix) # :yield: self
      @variables = []
      @endpoints = []
      yield self if block_given?
    end
    
  end
  
end