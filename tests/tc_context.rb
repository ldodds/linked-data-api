$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'linked-data-api'
require 'linked-data-api/mock.rb'
require 'test/unit'
require 'rack'

class ContextTest < Test::Unit::TestCase
  
  def test_untyped_variables_from_qs
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d")
    req = Rack::Request.new(env)    
    ctx = LinkedDataAPI::Context.new(req, nil)
    vars = ctx.sparql_variables()
    assert_equal("\"b\"", vars["a"])
    assert_equal("\"d\"", vars["c"])
  end
  
  def test_with_simple_typed_properties
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=2009-10-01")
    req = Rack::Request.new(env)    
    ctx = LinkedDataAPI::Context.new(req, nil) do |c|
      LinkedDataAPI::Term.new("http://www.example.org/prop", "a", "A", "http://www.w3.org/2001/XMLSchema#string").add_to_hash(c.terms) 
      LinkedDataAPI::Term.new("http://www.example.org/prop2", "c", "C", "http://www.w3.org/2001/XMLSchema#date").add_to_hash(c.terms)
    end    
    vars = ctx.sparql_variables()
    assert_equal("\"b\"", vars["a"])
    assert_equal("\"2009-10-01\"^^<http://www.w3.org/2001/XMLSchema#date>", vars["c"])    
  end
  
  def test_default_page_size()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    endpoint = LinkedDataAPI::Endpoint.new(api)
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(10, ctx.page_size())      
  end
  
  def test_default_page_size_from_endpoint()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    endpoint = LinkedDataAPI::Endpoint.new(api)
    endpoint.default_page_size = 11
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(11, ctx.page_size())    
  end
  
  def test_default_page_size_from_request()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d&_pageSize=12")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    endpoint = LinkedDataAPI::Endpoint.new(api)
    endpoint.default_page_size = 11
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(12, ctx.page_size())    
  end
  
  def test_max_page_size()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    endpoint = LinkedDataAPI::Endpoint.new(api)
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(nil, ctx.max_page_size())          
  end
  
  def test_max_page_size_from_endpoint()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    endpoint = LinkedDataAPI::Endpoint.new(api)
    endpoint.max_page_size = 13
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(13, ctx.max_page_size())          
  end
  
  def test_max_page_size_from_api()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    api.max_page_size = 12
    endpoint = LinkedDataAPI::Endpoint.new(api)
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(12, ctx.max_page_size())          
  end    
  
  def test_cannot_exceed_max_page_size_from_api()
    env = LinkedDataAPI::MockRequest.env_for("/test?a=b&c=d&_pageSize=22")
    req = Rack::Request.new(env)
    api = LinkedDataAPI::API.new()    
    api.max_page_size = 12
    endpoint = LinkedDataAPI::Endpoint.new(api)
    ctx = LinkedDataAPI::Context.new(req, endpoint)
    assert_equal(12, ctx.page_size())          
  end
  
end