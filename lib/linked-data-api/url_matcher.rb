module LinkedDataAPI

  class URLMatcher
  
    def URLMatcher.normalize_url(path, params, ignore=[])     
      return path if params == nil || params.size == 0
      sorted = params.sort
      if ignore.length > 0
        sorted = sorted.reject { |item| ignore.include?(item[0]) }        
      end      
      normalized_params = sorted.map { |item| "#{item[0]}=#{item[0]}" }.join("&")
      return path + "?" + normalized_params 
    end
    
    def URLMatcher.normalize_template(template)
      parts = template.split("?")
      if parts.length == 1
        return template
      end
      params = []
      parts[1].split("&").each { |kv|
        params << kv.split("=")[0]
      }
      return parts[0] + "?" + params.sort.map{ |item| "#{item}=#{item}"}.join("&")
    end
    
    def URLMatcher.match?(url, template, params, ignore=[])      
      normalized_url = normalize_url(url, params, ignore)
      normalized_template = normalize_template(template)
      #TODO path variables in templates
      return normalized_url == normalized_template
    end
          
  end  
  
end