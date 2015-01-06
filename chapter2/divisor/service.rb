require "sinatra/main"
require 'logger'

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }
set :raise_errors, false

get "/api/v1/ratio/:a/:b" do
  content_type :txt
  "#{params[:a].to_i / params[:b].to_i}"
end

error { [500, "An internal server error occurred. Please try again later."] }
