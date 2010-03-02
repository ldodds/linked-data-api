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
      
      if normalized_template.include?("{")
        compiled_template = normalized_template.gsub(/\{[^\/]+\}/, "([^\/]+)").gsub("/", "\/") + "$"
        if compiled_template.include?("?")
          return normalized_url.match(compiled_template) != nil
        else
          return normalized_url.split("?")[0].match(compiled_template) != nil
        end              
      else
        return normalized_url == normalized_template  
      end
    end
    
    def URLMatcher.extract(url, template, params, ignore=[])
      vars = {}
      if template.include?("{") && URLMatcher.match?(url, template, params, ignore)
        normalized_url = normalize_url(url, params, ignore)
        normalized_template = normalize_template(template)
        compiled_template = normalized_template.gsub(/\{[^\/]+\}/, "([^\/]+)").gsub("/", "\/") + "$"
        varnames = normalized_template.scan(/\{([^\/]+)\}/).flatten
        matches = normalized_url.match(compiled_template)
        varnames.each_with_index do |name, i|
          vars[name] = matches.captures[i]
        end
      end
      return vars
    end      
  end  
  
end