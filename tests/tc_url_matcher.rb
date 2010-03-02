$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'linked-data-api'

class LinkedDataAPI::URLMatcherTest < Test::Unit::TestCase
  
  def test_normalize_url  
    assert_equal("/test", LinkedDataAPI::URLMatcher.normalize_url("/test", {}) )      
  end

  def test_normalize_url_with_params  
    assert_equal("/test?foo=foo", LinkedDataAPI::URLMatcher.normalize_url("/test", {"foo" => "bar" }) )
    assert_equal("/test?abc=abc&foo=foo", LinkedDataAPI::URLMatcher.normalize_url("/test", {"foo" => "bar", "abc" => "def" }) )  
  end

  def test_normalize_url_with_ignores
    assert_equal("/test?foo=foo", LinkedDataAPI::URLMatcher.normalize_url("/test", {"foo" => "bar", "abc" => "def" }, ["abc"] ) )
  end
  
  def test_normalize_template
    assert_equal("/test", LinkedDataAPI::URLMatcher.normalize_template("/test") )  
  end        

  def test_normalize_template_with_params
    assert_equal("/test?foo=foo", LinkedDataAPI::URLMatcher.normalize_template("/test?foo={id}") )  
    assert_equal("/test?abc=abc&foo=foo", LinkedDataAPI::URLMatcher.normalize_template("/test?foo={id}&abc={def}") )
  end        
  
  def test_match?
    assert_equal( true, 
      LinkedDataAPI::URLMatcher.match?("/test", "/test?foo={id}&abc={def}", {"foo" => "bar", "abc" => "def" }) )
  end
  
  def test_match_with_template
    assert_equal( true, 
    LinkedDataAPI::URLMatcher.match?("/school/primary", "/school/{type}", {})
    )
    assert_equal( false, 
    LinkedDataAPI::URLMatcher.match?("/school/other/primary", "/school/{type}", {})
    )
    assert_equal( false, 
    LinkedDataAPI::URLMatcher.match?("/school/primary/other", "/school/{type}", {})
    )

  end

  def test_match_with_template_and_supplied_params
    assert_equal( true, 
    LinkedDataAPI::URLMatcher.match?("/school/primary", "/school/{type}", {"foo" => "bar", "abc" => "def" })
    )
    assert_equal( true, 
    LinkedDataAPI::URLMatcher.match?("/school/primary/other", "/school/{type}/other", {"foo" => "bar", "abc" => "def" })
    )
  end

  def test_match_with_template_and_required_param
    assert_equal( true, 
      LinkedDataAPI::URLMatcher.match?("/school/primary", "/school/{type}?foo={id}", {"foo" => "bar", "abc" => "def" }) )
    assert_equal( false, 
      LinkedDataAPI::URLMatcher.match?("/school/primary", "/school/{type}?foo={id}", {"abc" => "def" }) )    
  end
  
  def test_match_with_template_and_reserved_param
    assert_equal( true, 
      LinkedDataAPI::URLMatcher.match?("/school/primary", "/school/{style}", {"_sort" => "size" }) )
  end
  
  def test_extract
    vars = LinkedDataAPI::URLMatcher.extract("/school/primary", "/school/primary", {})
    assert_equal( true, vars.empty?)

    vars = LinkedDataAPI::URLMatcher.extract("/school/primary", "/school/{type}", {})
    assert_equal( "primary", vars["type"] )

    vars = LinkedDataAPI::URLMatcher.extract("/school/primary/other", "/school/{type}/other", {})
    assert_equal( "primary", vars["type"] )

    vars = LinkedDataAPI::URLMatcher.extract("/school/primary/closed", "/school/{type}/{status}", {})
    assert_equal( "primary", vars["type"] )
    assert_equal( "closed", vars["status"] )
                  
  end
  
end