$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'linked-data-api'
require 'test/unit'

class TermTest < Test::Unit::TestCase
  
  def test_bound
    p = LinkedDataAPI::Term.new("http://www.example.org/test", "test", "label", nil)
    assert_equal(true, p.bound?)
    
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, "label", nil)
    assert_equal(false, p.bound?)    
  end
  
  def test_name
    p = LinkedDataAPI::Term.new("http://www.example.org/test", "test", "label", nil)
    assert_equal("test", p.name)
    
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, "label", nil)
    assert_equal("label", p.name)    
  end

  def test_localname
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, nil)
    assert_equal("test", p.name)
    
    p = LinkedDataAPI::Term.new("http://www.example.org#test", nil, nil, nil)
    assert_equal("test", p.name)
  end  
  
  def test_to_sparql
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, nil)
    assert_equal("\"test\"", p.to_sparql("test"))
      
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, "http://www.w3.org/2000/01/rdf-schema#Resource")
    assert_equal("<test>", p.to_sparql("test"))

    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, "http://www.w3.org/2001/XMLSchema#int")
    assert_equal("123", p.to_sparql("123"))
      
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, "http://www.w3.org/2001/XMLSchema#float")
    assert_equal("123.0", p.to_sparql("123.0"))
      
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, "http://www.w3.org/2001/XMLSchema#date")
    assert_equal("\"2009-01-01\"^^<http://www.w3.org/2001/XMLSchema#date>", p.to_sparql("2009-01-01"))
      
    p = LinkedDataAPI::Term.new("http://www.example.org/test", nil, nil, "http://www.w3.org/2001/XMLSchema#string")
    assert_equal("\"test\"", p.to_sparql("test"))                
  end
  
  def test_class
    cls = LinkedDataAPI::Term.create_class("http://xmlns.com/foaf/0.1/Person", "person", "Person")
    assert_equal("person", cls.name)
    assert_equal("<http://xmlns.com/foaf/0.1/Person>", cls.to_sparql("foo"))
    cls = LinkedDataAPI::Term.create_class("http://www.example.com/geek-types/Hacker", "Hacker")
    assert_equal("Hacker", cls.name)
    assert_equal("<http://www.example.com/geek-types/Hacker>", cls.to_sparql("foo"))
    
  end  
end