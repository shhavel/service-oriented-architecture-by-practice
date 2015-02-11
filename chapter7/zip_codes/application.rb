require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }

Dir[File.join(settings.root, "app/{models,controllers}/*.rb")].each { |f| require f }

use Rack::PostBodyContentTypeParser
before { content_type :json }
ActiveRecord::Base.include_root_in_json = true

user do
  if request.env['HTTP_AUTHORIZATION'].present?
    response = Faraday.new("http://localhost:4545/api/v1/users/me.json",
      headers: { 'Authorization' => request.env['HTTP_AUTHORIZATION'] }).get
    halt 401 if response.status == 401 # go to error 401 handler
    OpenStruct.new(JSON.parse(response.body)['user']) if response.success?
  end
end

error(401) { '{"message":"Invalid or expired token"}' }
error(403) { '{"message":"Access Forbidden"}' }
error(404, ActiveRecord::RecordNotFound) { [404, '{"message":"Record not found"}'] }
error(ActiveRecord::RecordInvalid) do
  [422, { message: "Validation errors occurred",
          errors:  env['sinatra.error'].record.errors.messages }.to_json ]
end
error { '{"message":"An internal server error occurred. Please try again later."}' }
