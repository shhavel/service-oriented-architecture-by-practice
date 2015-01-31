require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
require 'logger'
require_relative 'rusen_config'

disable :show_exceptions # in production it is false, so you probably do not need it
disable :raise_errors # in production and dev mode it is false, so you probably do not need it
set :root, File.dirname(__FILE__)
log_file = File.new(File.join(settings.root, 'log', "#{settings.environment}.log"), 'a+')
log_file.sync = true
use Rack::CommonLogger, log_file
logger = Logger.new(log_file)
logger.formatter = ->(severity, time, progname, msg) { "#{msg}\n" }

before do
  env['rack.logger'] = logger
end

get "/api/v1/ratio/:a/:b" do
  logger.info "compute the result of integer division #{params[:a]} / #{params[:b]}"
  content_type :txt
  "#{params[:a].to_i / params[:b].to_i}"
end

error do
  # Arguments are: exception, request, environment, session
  Rusen.notify(env['sinatra.error'], {}, env, {}) # if settings.production?
  "An internal server error occurred. Please try again later."
end
