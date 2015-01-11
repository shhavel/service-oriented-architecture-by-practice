require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }

require "sinatra/activerecord"
Dir[File.join(settings.root, "app/models/*.rb")].each { |f| autoload File.basename(f, '.rb').classify.to_sym, f }
Dir[File.join(settings.root, "app/controllers/*.rb")].each { |f| require f }

before do
  content_type :json
end

error(ActiveRecord::RecordNotFound) { [404, '{"message":"Record not found"}' }
error(ActiveRecord::RecordInvalid) do
  [422, { message: "Validation errors occurred",
          errors:  env['sinatra.error'].record.errors.messages }.to_json ]
end
error { '{"message":"An internal server error occurred. Please try again later."}' }
