require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }

Dir[File.join(settings.root, "app/{models,controllers}/*.rb")].each { |f| require f }

# Support for JSON request bodies
use Rack::PostBodyContentTypeParser

# Adds "Content-Type: application/json" HTTP header in response
before { content_type :json }

# Configure method ActiveRecord::Base#to_json to add root node at top level,
# e.g. {"zip_code":{"zip": ... }}
ActiveRecord::Base.include_root_in_json = true
