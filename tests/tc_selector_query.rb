$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'linked-data-api'
require 'linked-data-api/mock.rb'
require 'test/unit'
require 'rack'

class SelectorQueryTest < Test::Unit::TestCase
  
  def create_context_for(path)
    env = LinkedDataAPI::MockRequest.env_for(path)
    req = Rack::Request.new(env)    
    ctx = LinkedDataAPI::Context.new(req, nil)    
    return ctx    
  end

  def test_select_query_with_default
    ctx = create_context_for("/foo")
    selector = LinkedDataAPI::Selector.new()
    query = selector.select_query(ctx)
    assert_equal("SELECT ?item WHERE {\n?item ?property ?value.\n}", query)    
  end

  def test_select_query_with_where
    ctx = create_context_for("/foo?_where=WHERE")
    selector = LinkedDataAPI::Selector.new()
    query = selector.select_query(ctx)
    assert_equal("SELECT ?item WHERE {\nWHERE.}", query)    
  end
    
  def test_select_query_with_prefixes
    ctx = create_context_for("/foo")
    ctx.namespaces["foaf"] = "http://xmlns.com/foaf/0.1/"
    selector = LinkedDataAPI::Selector.new()
    query = selector.select_query(ctx)
    assert_equal("PREFIX foaf: <http://xmlns.com/foaf/0.1/>\nSELECT ?item WHERE {\n?item ?property ?value.\n}", query)    
  end
    
  def test_select_query_with_property
    p = LinkedDataAPI::Term.create_property("http://xmlns.com/foaf/0.1/name", "name")
    ctx = create_context_for("/person?name=Leigh")
    p.add_to_hash(ctx.terms)
    selector = LinkedDataAPI::Selector.new()
    query = selector.select_query(ctx)
    assert_equal("SELECT ?item WHERE {\n?item <http://xmlns.com/foaf/0.1/name> \"Leigh\".\n}", query)      
  end

  def test_select_with_where_and_orderby
    ctx = create_context_for("/person")    
    ctx.namespaces["foaf"] = "http://xmlns.com/foaf/0.1/"
    ctx.namespaces["ex"] = "http://www.example.org/"
    selector = LinkedDataAPI::Selector.new()
    selector.where = "?item a foaf:Person; ex:age ?age."
    selector.order_by = "DESC(?age)"
    query = selector.select_query(ctx)
    lines = query.split("\n")
    assert_equal("PREFIX ex: <http://www.example.org/>", lines[0])
    assert_equal("PREFIX foaf: <http://xmlns.com/foaf/0.1/>", lines[1])
    assert_equal("SELECT ?item WHERE {", lines[2])
    assert_equal("?item a foaf:Person; ex:age ?age.}", lines[3])
    assert_equal("ORDER BY DESC(?age)", lines[4])
  end  
  
  def test_select_query_with_asc_sort
    ctx = create_context_for("/person?_sort=age")        
    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.example.org/age", "age")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Person"
    query = selector.select_query(ctx)
    lines = query.split("\n")
    assert_equal(5, lines.size)
    assert_equal("SELECT ?item WHERE {", lines[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", lines[1])      
    assert_equal("?item <http://www.example.org/age> ?sort_age.", lines[2])
    assert_equal("}", lines[3])
    assert_equal("ORDER BY ASC(?sort_age)", lines[4].sub(/ $/,""))    
  end  

  def test_select_query_with_desc_sort
    ctx = create_context_for("/person?_sort=-age")        
    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.example.org/age", "age")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Person"
    query = selector.select_query(ctx)
    lines = query.split("\n")
    assert_equal(5, lines.size)
    assert_equal("SELECT ?item WHERE {", lines[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", lines[1])      
    assert_equal("?item <http://www.example.org/age> ?sort_age.", lines[2])
    assert_equal("}", lines[3])
    assert_equal("ORDER BY DESC(?sort_age)", lines[4].sub(/ $/,""))    
  end  

  def test_select_query_with_combined_sort
    ctx = create_context_for("/person?_sort=age,-shoeSize")        
    p = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "Person")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.example.org/age", "age")
    p.add_to_hash(ctx.terms)
    p = LinkedDataAPI::Term.create_property("http://www.example.org/shoeSize", "shoeSize")
    p.add_to_hash(ctx.terms)    
    p = LinkedDataAPI::Term.create_property("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
    p.add_to_hash(ctx.terms)    
    selector = LinkedDataAPI::Selector.new()
    selector.filter="type=Person"
    query = selector.select_query(ctx)
    lines = query.split("\n")
    assert_equal(6, lines.size)
    assert_equal("SELECT ?item WHERE {", lines[0])
    assert_equal("?item <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person>.", lines[1])      
    assert_equal("?item <http://www.example.org/age> ?sort_age.", lines[2])
    assert_equal("?item <http://www.example.org/shoeSize> ?sort_shoeSize.", lines[3])
    assert_equal("}", lines[4])
    assert_equal("ORDER BY ASC(?sort_age) DESC(?sort_shoeSize)", lines[5].sub(/ $/,""))    
  end
  
          
end