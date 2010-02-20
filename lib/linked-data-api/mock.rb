module LinkedDataAPI
  
  class MockRequest
          
      DEFAULT_ENV = {
        "rack.version" => [0,1],
        "rack.input" => StringIO.new,
        "rack.errors" => StringIO.new,
        "rack.multithread" => true,
        "rack.multiprocess" => true,
        "rack.run_once" => false,
      }
          
      def MockRequest.env_for(uri="", opts={})
        uri = URI(uri)
        env = DEFAULT_ENV.dup
  
        env["REQUEST_METHOD"] = opts[:method] || "GET"
        env["SERVER_NAME"] = uri.host || "example.org"
        env["SERVER_PORT"] = uri.port ? uri.port.to_s : "80"
        env["QUERY_STRING"] = uri.query.to_s
        env["PATH_INFO"] = (!uri.path || uri.path.empty?) ? "/" : uri.path
        env["rack.url_scheme"] = uri.scheme || "http"
  
        env["SCRIPT_NAME"] = opts[:script_name] || ""
  
        if opts[:fatal]
          env["rack.errors"] = FatalWarner.new
        else
          env["rack.errors"] = StringIO.new
        end
  
        opts[:input] ||= ""
        if String === opts[:input]
          env["rack.input"] = StringIO.new(opts[:input])
        else
          env["rack.input"] = opts[:input]
        end
  
        env["CONTENT_LENGTH"] ||= env["rack.input"].length.to_s
  
        opts.each { |field, value|
          env[field] = value  if String === field
        }
  
        env  
      end  
        
  end
  
end