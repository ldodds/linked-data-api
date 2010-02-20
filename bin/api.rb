$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'
require 'sinatra'
require 'pho'
require 'linked-data-api'

get '/*' do
 @api = LinkedDataAPI::API.from_file("api.ttl")
 #puts request.url  
 puts request
 puts request.path
 puts params.inspect
 params.delete("splat")
 req = LinkedDataAPI::Request.new(request.url, request.path, params)
 resp = @api.apply(req) 
 content_type resp.mimetype
 resp.content
end
