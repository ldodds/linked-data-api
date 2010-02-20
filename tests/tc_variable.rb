$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'linked-data-api'
require 'test/unit'

class VariableTest < Test::Unit::TestCase
  
  def test_to_sparql
    v = LinkedDataAPI::Variable.new("test", "test", nil)
    assert_equal("\"test\"", v.to_sparql())
      
    v = LinkedDataAPI::Variable.new("test", "test", "http://www.w3.org/2000/01/rdf-schema#Resource")
    assert_equal("<test>", v.to_sparql())
      
    v = LinkedDataAPI::Variable.new("test", "123", "http://www.w3.org/2001/XMLSchema#int")
    assert_equal("123", v.to_sparql())
      
    v = LinkedDataAPI::Variable.new("test", "123.0", "http://www.w3.org/2001/XMLSchema#float")
    assert_equal("123.0", v.to_sparql())
      
    v = LinkedDataAPI::Variable.new("test", "2009-01-01", "http://www.w3.org/2001/XMLSchema#date")
    assert_equal("\"2009-01-01\"^^<http://www.w3.org/2001/XMLSchema#date>", v.to_sparql())
      
    v = LinkedDataAPI::Variable.new("test", "test", "http://www.w3.org/2001/XMLSchema#string")
    assert_equal("\"test\"", v.to_sparql())                
  end
    
end