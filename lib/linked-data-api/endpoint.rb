module LinkedDataAPI

  class Endpoint
  
    #uri template for matching
    attr_accessor :uriTemplate
    #item template for building uris
    attr_accessor :itemTemplate
    #reference to api
    attr_accessor :api
    #Selector
    attr_accessor :selector
    #Viewer
    attr_accessor :viewer
    #List of Formatters
    attr_accessor :formatters
    #List of Variables
    attr_accessor :variables
    #Default page size
    attr_accessor :default_page_size
    attr_accessor :max_page_size
    
    def initialize(api=nil, uriTemplate=nil, selector=nil, itemTemplate=nil) # :yield: self
        @api = api
        @uriTemplate = uriTemplate
        @selector = selector
        @itemTemplate = itemTemplate
        @variables = []
        @formatters = []        
        #TODO default built in viewer
        #TODO default built in formatter(s)
        yield self if block_given?      
    end
    
    def variables()
      #TODO make sure others are shadowed
      return @variables
    end
    
    def default_page_size()
      return @api.default_page_size if @default_page_size == nil && api != nil
      return @default_page_size
    end
    
    def max_page_size()
      return @api.max_page_size if @max_page_size == nil && api != nil
      return @max_page_size
    end
  end  
  
end