$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'linked-data-api'
require 'linked-data-api/mock.rb'
require 'test/unit'
require 'rack'

class SelectorTest < Test::Unit::TestCase
  
  def create_context_for(path)
    env = LinkedDataAPI::MockRequest.env_for(path)
    req = Rack::Request.new(env)    
    ctx = LinkedDataAPI::Context.new(req, nil)    
    return ctx    
  end

  def test_for_default_pattern  
    ctx = create_context_for("/foo")
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item ?property ?value.\n", pattern)  
  end  
  
  def test_for_where_in_query_string
    ctx = create_context_for("/foo?_where=WHERE")
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("WHERE", pattern)      
  end
  
  def test_for_where
    ctx = create_context_for("/foo?")
    selector = LinkedDataAPI::Selector.new()
    selector.where = "WHERE"
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("WHERE", pattern)      
  end
  
  def test_for_where_in_query_string_override
    ctx = create_context_for("/foo?_where=WHERE")
    selector = LinkedDataAPI::Selector.new()
    selector.where="NOT-THIS"
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("WHERE", pattern)      
  end    
  
  def test_unbound_parameters_dont_contribute_to_pattern
    ctx = create_context_for("/foo?a=b&c=d")
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item ?property ?value.\n", pattern)      
  end

 
  def test_bound_query_parameter_adds_to_pattern
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")
    ctx = create_context_for("/person?name=Leigh")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".\n", pattern)      
  end

  def test_multiple_bound_query_parameters_adds_to_pattern
    ctx = create_context_for("/person?type=Hacker&name=Leigh")
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")    
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.example.com/geek-types/Hacker", "Hacker")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    triple_patterns = pattern.split("\n")    
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".", triple_patterns[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#> <http://www.example.com/geek-types/Hacker>.", triple_patterns[1])      
  end
  
  def test_filter_parameter_adds_to_pattern
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")
    ctx = create_context_for("/person")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    selector.filter="name=Leigh"
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".\n", pattern)          
  end
  
  def test_filter_parameter_with_variable
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")
    ctx = create_context_for("/person?x=Leigh")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    selector.filter="name={x}"
    pattern = selector.create_graph_pattern(ctx)
    assert_equal(1, pattern.split("\n").size)
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".\n", pattern)          
  end
    
  def test_multiple_filter_parameters_adds_to_pattern
    ctx = create_context_for("/person")
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")    
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.example.com/geek-types/Hacker", "Hacker")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Hacker&name=Leigh"
    pattern = selector.create_graph_pattern(ctx)
    triple_patterns = pattern.split("\n")    
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".", triple_patterns[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.example.com/geek-types/Hacker>.", triple_patterns[1])      
  end    
  
  def test_filter_parameters_and_query_parameters_combine
    ctx = create_context_for("/person?name=Leigh")
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")    
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.example.com/geek-types/Hacker", "Hacker")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Hacker"
    pattern = selector.create_graph_pattern(ctx)
    triple_patterns = pattern.split("\n")    
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".", triple_patterns[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.example.com/geek-types/Hacker>.", triple_patterns[1])          
  end
  
  def test_query_parameters_override_filter_parameters
    ctx = create_context_for("/person?type=Person&name=Leigh")
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")    
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://www.example.com/geek-types/Hacker", "Hacker")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
    p.add_to_hash(ctx.terms)    
    p = LinkedDataAPI::Term.create_class("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Hacker"
    pattern = selector.create_graph_pattern(ctx)
    triple_patterns = pattern.split("\n")    
    assert_equal(2, triple_patterns.size)
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".", triple_patterns[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", triple_patterns[1])          
  end
  
  def test_with_property_path
    ctx = create_context_for("/test?localAuthority.code=00BX")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/geography/localAuthority", "localAuthority")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.example.org/geography/code", "code")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal(1, pattern.split("\n").size)
    assert_equal("?item <http://www.example.org/geography/localAuthority> [ <http://www.example.org/geography/code> \"00BX\" ].\n", pattern)              
  end
  
end
