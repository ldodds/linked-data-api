$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'linked-data-api'
require 'linked-data-api/mock.rb'
require 'test/unit'
require 'rack'

class SelectorGraphPatternTest < Test::Unit::TestCase
  
  def create_context_for(path)
    env = LinkedDataAPI::MockRequest.env_for(path)
    req = Rack::Request.new(env)    
    ctx = LinkedDataAPI::Context.new(req, nil)    
    return ctx    
  end

  #
  # Tests for basic graph pattern assembly
  #
  
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
    assert_equal("WHERE.", pattern)      
  end
  
  def test_for_where
    ctx = create_context_for("/foo?")
    selector = LinkedDataAPI::Selector.new()
    selector.where = "WHERE"
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("WHERE.", pattern)      
  end
  
  def test_for_where_in_query_string_override
    ctx = create_context_for("/foo?_where=WHERE")
    selector = LinkedDataAPI::Selector.new()
    selector.where="NOT-THIS"
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("WHERE.", pattern)      
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
    p = LinkedDataAPI::Term.create_class("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    triple_patterns = pattern.split("\n")    
    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".", triple_patterns[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.example.com/geek-types/Hacker>.", triple_patterns[1])      
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
    assert_equal("?item <http://www.example.org/geography/localAuthority> [ <http://www.example.org/geography/code> \"00BX\". ].\n", pattern)              
  end

  def test_with_min_prefix
    ctx = create_context_for("/test?min-size=10")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/size", "size")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://www.example.org/size> ?min_size. FILTER ( ?min_size >= \"10\" ).\n", pattern)              
  end

  def test_with_max_prefix
    ctx = create_context_for("/test?max-size=10")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/size", "size")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://www.example.org/size> ?max_size. FILTER ( ?max_size <= \"10\" ).\n", pattern)              
  end

  def test_with_minEx_prefix
    ctx = create_context_for("/test?minEx-size=10")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/size", "size")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://www.example.org/size> ?minEx_size. FILTER ( ?minEx_size > \"10\" ).\n", pattern)              
  end

  def test_with_maxEx_prefix
    ctx = create_context_for("/test?maxEx-size=10")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/size", "size")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://www.example.org/size> ?maxEx_size. FILTER ( ?maxEx_size < \"10\" ).\n", pattern)              
  end
  
  def test_with_exists_prefix
    ctx = create_context_for("/test?exists-size=true")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/size", "size")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://www.example.org/size> ?exists_size.\n", pattern)              
  end

  def test_with_exists_prefix_when_false
    ctx = create_context_for("/test?exists-size=false")    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/size", "size")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("OPTIONAL { ?item <http://www.example.org/size> ?exists_size. } FILTER ( !bound(?exists_size) ).\n", pattern)              
  end
    
  def test_with_name_prefix
    ctx = create_context_for("/test?name-knows=Leigh")    
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/knows", "knows")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    pattern = selector.create_graph_pattern(ctx)
    assert_equal("?item <http://xmlns.com/foaf/0.1/knows> ?name_knows. ?name_knows <http://www.w3.org/2000/01/rdf-schema#label> \"Leigh\".\n", pattern)              
  end


  def test_sort_specs_are_added_to_graph_pattern
    ctx = create_context_for("/person?_sort=age")        
    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.example.org/age", "age")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Person"
    pattern = selector.create_graph_pattern(ctx)
    lines = pattern.split("\n")
    assert_equal(2, lines.size)
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", lines[0])      
    assert_equal("?item <http://www.example.org/age> ?sort_age.", lines[1])
  end

  def test_sort_specs_with_property_paths_are_added_to_graph_pattern
    ctx = create_context_for("/person?_sort=knows.age")        
    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/knows", "knows")
    p.add_to_hash(ctx.terms)    
    p = LinkedDataAPI::Term.create_property("http://www.example.org/age", "age")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Person"
    pattern = selector.create_graph_pattern(ctx)
    lines = pattern.split("\n")
    assert_equal(2, lines.size)
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", lines[0])      
    assert_equal("?item <http://xmlns.com/foaf/0.1/knows> [ <http://www.example.org/age> ?sort_knows_age. ].", lines[1])
  end

#OK Below
        
#  def test_redundant_sort_specs_are_not_added_to_graph_pattern_with_filters
#    ctx = create_context_for("/person?_sort=age")        
#    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
#    p.add_to_hash(ctx.terms)
#    p = LinkedDataAPI::Term.create_property("http://www.example.org/age", "age")
#    p.add_to_hash(ctx.terms)
#    p = LinkedDataAPI::Term.create_property("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
#    p.add_to_hash(ctx.terms)    
#    selector = LinkedDataAPI::Selector.new()
#    selector.filter="min-age=10&type=Person"
#    pattern = selector.create_graph_pattern(ctx)
#    lines = pattern.split("\n")
#    puts pattern
#    assert_equal(2, lines.size)
#    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", lines[0])
#    #don't have extra filter, cos we can reuse the variable      
#    assert_equal("?item <http://www.example.org/age> ?min_age. FILTER ( ?min_age >= \"10\" ).", lines[1])
#  end
    
#  def test_redundant_sort_specs_are_not_added_to_graph_pattern_with_value_tests
#    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")
#    ctx = create_context_for("/person?name=Leigh&_sort=name")
#    p.add_to_hash(ctx.terms)
#    selector = LinkedDataAPI::Selector.new()
#    pattern = selector.create_graph_pattern(ctx)
#    puts pattern
#    assert_equal(1, pattern.split("\n").size)
#    assert_equal("?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".\n", pattern)          
#  end  
                      
end
