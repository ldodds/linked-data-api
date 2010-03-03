module LinkedDataAPI
  
  #An API over a Linked Data source
  class API
    
    attr_accessor :sparql_endpoint, :base, :content_negotiation, :variables, :endpoints
    attr_accessor :default_page_size, :max_page_size
    
    #Create an api for a specific sparql endpoint. Default content negotation type is based on suffix (:suffix). 
    #Alternate is :parameter
    def initialize(sparql_endpoint=nil, base=nil, content_negotiation=:suffix) # :yield: self
      @sparql_endpoint = sparql_endpoint
      @base = base
      @content_negotiation = content_negotiation 
      @variables = []
      @endpoints = []
      @default_page_size = 10
      yield self if block_given?
    end
    
    #TODO match
  end
  
end