Chapter #7. Authentication and Authorization
============================================

We need think about security and access rights, currently Zip codes Web service is fully public - anyone can create new Zip code and update or delete existent. Let's develop remote authorization through users Web service created in chapter #4. All registered users will be able to create new Zip code and only admin users will be able update or delete existent Zip code.

To authenticate itself web service cliend should provide token in HTTP header (by service design that we do now). Zip code service will use this same token to get user identity from users service. So internally for create/update/delete HTTP requests Zip code service performs (it will) one more HTTP request - this is minor performance overhead, you should take remote calls into account when developing service architecture.

## Remote calls to users service 

Recall users service that was created in chapter #4 - we plan to use it for authentication in Zip codes service. Please do some minor investigation about how we will call users service from ruby code. We need HTTP client library like [faraday](https://github.com/lostisland/faraday). Install it please.

    $ gem install faraday

Then run please users service on port 4545 (run in terminal from users dir)

    $ ruby service.rb -p 4545

Onen new terminal tab and start `irb` session (type `irb` and press `Enter`). Here is our session:

    $ irb
    > require "faraday"
    => true
    > response = Faraday.new("http://localhost:4545/api/v1/users/me.json",
    > headers: { "Authorization" => "OAuth b259ca1339e168b8295287648271acc94a9b3991c608a3217fecc25f369aaa86" }).get
    => #<Faraday::Response:0x0000010199d1d8 @on_complete_callbacks=[], @env=#<Faraday::Env @method=:get @body="{\"user\":{\"type\":\"RegularUser\"}}" @url=#<URI::HTTP:0x000001019abc60 URL:http://localhost:4545/api/v1/users/me.json> @request=#<Faraday::RequestOptions (empty)> @request_headers={"Authorization"=>"OAuth b259ca1339e168b8295287648271acc94a9b3991c608a3217fecc25f369aaa86", "User-Agent"=>"Faraday v0.9.1"} @ssl=#<Faraday::SSLOptions (empty)> @response_headers={"content-type"=>"application/json", "content-length"=>"31", "x-content-type-options"=>"nosniff", "connection"=>"close", "server"=>"thin"} @status=200>>
    > response.status
    => 200
    > response.body
    => "{\"user\":{\"type\":\"RegularUser\"}}"

We have used correct token for "RegularUser". Let's try incorrect token.

    $ irb
    > require "faraday"
    => true
    > response = Faraday.new("http://localhost:4545/api/v1/users/me.json",
    > headers: { "Authorization" => "OAuth incorrect" }).get
    => #<Faraday::Response:0x00000101097a70 @on_complete_callbacks=[], @env=#<Faraday::Env @method=:get @body="{\"message\":\"Invalid or expired token\"}" @url=#<URI::HTTP:0x0000010183a020 URL:http://localhost:4545/api/v1/users/me.json> @request=#<Faraday::RequestOptions (empty)> @request_headers={"Authorization"=>"OAuth incorrect", "User-Agent"=>"Faraday v0.9.1"} @ssl=#<Faraday::SSLOptions (empty)> @response_headers={"content-type"=>"application/json", "content-length"=>"38", "x-content-type-options"=>"nosniff", "connection"=>"close", "server"=>"thin"} @status=401>>
    > response.status
    => 401
    > response.body
    => "{\"message\":\"Invalid or expired token\"}"

We can implement same logic in Zip codes service. HTTP Authorization header available in sinatra as request.env['HTTP_AUTHORIZATION'].

## Remote authentication

We will use light authorization Gem for Ruby on Rails - [cancan](https://github.com/ryanb/cancan) and sinatra wrapper for it - [sinatra-can](https://github.com/shf/sinatra-can). We will need gem [fakeweb](https://github.com/facewatch/fakeweb) to emulate calls to users service in tests. Please add three gems into `Gemfile`:

```ruby
source 'https://rubygems.org'

gem 'rake'
gem 'sinatra', require: 'sinatra/main'
gem 'rack-contrib', git: 'https://github.com/rack/rack-contrib'
gem 'pg'
gem 'activerecord'
gem 'protected_attributes'
gem 'sinatra-activerecord'
gem 'sinatra-param'

# Simple, but flexible HTTP client library, with support for multiple backends. 
gem 'faraday'

# CanCan wrapper for Sinatra. (CanCan is Authorization Gem for Ruby on Rails)
gem 'sinatra-can'

group :development, :test do
  gem 'thin'
  gem 'pry-debugger'
  gem 'rspec_api_documentation'
end

group :test do
  gem 'rspec'
  gem 'shoulda'
  gem 'factory_girl'
  gem 'database_cleaner'
  gem 'rack-test'
  gem 'faker'

  # A test helper for faking responses to web requests
  gem 'fakeweb'
end
```

And rum (from `zip_codes` dir in terminal)

    $ bundle install

We will use helper methods from `sinatra-can` to set up current user and current ability. We also need error handlers for 401 and 403 errors. Please update `application.rb`

```ruby
rrequire 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }

Dir[File.join(settings.root, "app/{models,controllers}/*.rb")].each { |f| require f }

use Rack::PostBodyContentTypeParser
before { content_type :json }
ActiveRecord::Base.include_root_in_json = true

# Set up current_user
user do
  if request.env['HTTP_AUTHORIZATION'].present?
    response = Faraday.new("http://localhost:4545/api/v1/users/me.json",
      headers: { 'Authorization' => request.env['HTTP_AUTHORIZATION'] }).get
    halt 401 if response.status == 401 # go to error 401 handler
    OpenStruct.new(JSON.parse(response.body)['user']) if response.success?
  end
end

# Set up current_ability
ability do |user|
  can :manage, ZipCode if user.present? && user.type == 'AdminUser'
  can :create, ZipCode if user.present? && user.type == 'RegularUser'
end

# Client uses incorrect token
error(401) { '{"message":"Invalid or expired token"}' }

# Operation forbidden (user can be logged in with token or public)
error(403) { '{"message":"Access Forbidden"}' }

error(ActiveRecord::RecordNotFound) { [404, '{"message":"Record not found"}'] }
error(ActiveRecord::RecordInvalid) do
  [422, { message: "Validation errors occurred",
          errors:  env['sinatra.error'].record.errors.messages }.to_json ]
end
error { '{"message":"An internal server error occurred. Please try again later."}' }
```

And check ability in `app/controllers/zip_codes_controller.rb` with helper method `authorize!` from `sinatra-can`.

post "/api/v1/zip_codes.json" do
  param :zip_code, Hash
  zip_code = ZipCode.new(params[:zip_code])
  authorize! :create, zip_code # Authorize create new ZipCode
  zip_code.save!
  status 201
  zip_code.to_json
end

# No authorization - available for not logged in users
get "/api/v1/zip_codes/:zip.json" do
  param :zip, String, format: /\A\d{5}(?:-\d{4})?\Z/
  zip_code = ZipCode.find_by_zip!(params[:zip])
  zip_code.to_json
end

put "/api/v1/zip_codes/:id.json" do
  param :id, Integer, max: 2147483647
  param :zip_code, Hash
  zip_code = ZipCode.find(params[:id])
  authorize! :update, zip_code # Authorize update ZipCode
  zip_code.update_attributes!(params[:zip_code]) if params[:zip_code].any?
  zip_code.to_json
end

delete "/api/v1/zip_codes/:id.json" do
  param :id, Integer, max: 2147483647
  zip_code = ZipCode.find(params[:id])
  authorize! :destroy, zip_code # Authorize destroy ZipCode
  zip_code.destroy!
end

## Emulate remote authentication in tests

We need to fix acceptance tests. There are six failed tests - all due public access to protected actions - get 403 error on attempt to modify Zip code.
First you chould be notified if serice performs external HTTP request (in our case to users) service. Modify `spec/spec_helper.rb` - add line `FakeWeb.allow_net_connect = false`

```ruby
ENV['RACK_ENV'] = 'test'
require File.expand_path("../../application", __FILE__)

FactoryGirl.find_definitions

# Catch when requests are made for unregistered URIs.
FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods
  config.default_formatter = 'doc' if config.files_to_run.one?

  def app
    Sinatra::Application
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

require "rspec_api_documentation/dsl"

RspecApiDocumentation.configure do |config|
  config.docs_dir = Pathname.new(Sinatra::Application.root).join("doc")
  config.app = Sinatra::Application
  config.api_name = "Zip Codes API"
  config.format = :html
  config.curl_host = 'https://zipcodes.example.com'
  config.curl_headers_to_filter = %w(Host Cookie)
end
```

When client does not pass OAuth token - service does not perform call to user service. So we should emulate pass token in tests.

```ruby
header "Authorization", 'OAuth abcdefgh12345678'
```

Method [header](https://github.com/zipmark/rspec_api_documentation#header) is defined in gem `rspec_api_documentation`.

And emulate HTTP response from users service

```ruby
FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
  body: '{"user":{"id":1,"type":"AdminUser"}}')
```

Here is updated version of `spec/acceptance/zip_codes_spec.rb`

```ruby
require "spec_helper"

resource 'ZipCode' do
  post "/api/v1/zip_codes.json" do
    header "Content-Type", "application/json"

    parameter :zip, "Zip", scope: :zip_code, required: true
    parameter :street_name, "Street name", scope: :zip_code
    parameter :building_number, "Building number", scope: :zip_code
    parameter :city, "City", scope: :zip_code
    parameter :state, "State", scope: :zip_code
    let(:raw_post) { params.to_json }

    # let(:valid_attributes) do
    #   { zip: "35761-7714", street_name: "Lavada Creek",
    #       building_number: "88871", city: "New Herminaton", state: "Rhode Island" }
    # end
    let(:valid_attributes) { attributes_for(:zip_code) }
    let(:new_zip_code) { ZipCode.last }

    context "Public User", document: nil do
      example "Create Zip Code" do
        do_request(zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 403
        expect(json_response).to eq(message: "Access Forbidden")
        expect(new_zip_code).to be_nil
      end
    end

    context 'Regular User (authenticated user with type "RegularUser")' do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"RegularUser"}}') }

      example "Create Zip Code by Regular User" do
        do_request(zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 201
        expect(json_response[:zip_code].values_at(*valid_attributes.keys)).to eq valid_attributes.values
        expect(new_zip_code).to be_present
        expect(new_zip_code.attributes.values_at(*valid_attributes.keys.map(&:to_s))).to eq valid_attributes.values
      end

      example "Create Zip Code with invalid params", document: nil do
        do_request(zip_code: { zip: "1234" })

        expect(status).to eq 422
        expect(response_body).to eq '{"message":"Validation errors occurred","errors":{"zip":["is invalid"]}}'
        expect(new_zip_code).to be_nil
      end

      example "Create Zip Code provide not Hash zip_code params", document: nil do
        do_request(zip_code: "STRING")

        expect(status).to eq 422
      end
    end

    context 'Admin User', document: nil do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"AdminUser"}}') }

      example "Create Zip Code" do
        do_request(zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 201
        expect(json_response[:zip_code].values_at(*valid_attributes.keys)).to eq valid_attributes.values
        expect(new_zip_code).to be_present
        expect(new_zip_code.attributes.values_at(*valid_attributes.keys.map(&:to_s))).to eq valid_attributes.values
      end
    end
  end

  get "/api/v1/zip_codes/:zip.json" do
    parameter :zip, "Zip", scope: :zip_code, required: true

    let(:zip_code) { create(:zip_code) }

    context "Public User" do
      example "Read Zip Code" do
        do_request(zip: zip_code.zip)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 200
        expect(json_response[:zip_code].values_at(:id, :zip, :street_name, :building_number, :city, :state)).to eq(
          zip_code.attributes.values_at('id', 'zip', 'street_name', 'building_number', 'city', 'state'))
      end

      example "Read Zip Code that does not exist", document: nil do
        do_request(zip: '12345-6789')

        expect(status).to eq 404
        expect(response_body).to eq '{"message":"Record not found"}'
      end

      example "Read Zip Code provide invalid format zip", document: nil do
        do_request(zip: '1234')
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 400
        expect(json_response[:message]).to eq 'Invalid Parameter: zip'
        expect(json_response[:errors][:zip]).to eq 'Parameter must match format (?-mix:\A\d{5}(?:-\d{4})?\Z)'
      end
    end

    context 'Regular User (authenticated user with type "RegularUser")', document: nil do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"RegularUser"}}') }

      example "Read Zip Code" do
        do_request(zip: zip_code.zip)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 200
        expect(json_response[:zip_code].values_at(:id, :zip, :street_name, :building_number, :city, :state)).to eq(
          zip_code.attributes.values_at('id', 'zip', 'street_name', 'building_number', 'city', 'state'))
      end
    end

    context "Admin User", document: nil do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"AdminUser"}}') }

      example "Read Zip Code" do
        do_request(zip: zip_code.zip)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 200
        expect(json_response[:zip_code].values_at(:id, :zip, :street_name, :building_number, :city, :state)).to eq(
          zip_code.attributes.values_at('id', 'zip', 'street_name', 'building_number', 'city', 'state'))
      end
    end
  end

  put "/api/v1/zip_codes/:id.json" do
    header "Content-Type", "application/json"

    parameter :id, "Record ID", required: true
    parameter :street_name, "Street name", scope: :zip_code
    parameter :building_number, "Building number", scope: :zip_code
    parameter :city, "City", scope: :zip_code
    parameter :state, "State", scope: :zip_code
    let(:raw_post) { params.to_json }

    let(:zip_code) { create(:zip_code) }
    let(:valid_attributes) { attributes_for(:zip_code) }

    context "Public User", document: nil do
      example "Update Zip Code" do
        do_request(id: zip_code.id, zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 403
        expect(json_response).to eq(message: "Access Forbidden")
      end
    end

    context 'Regular User (authenticated user with type "RegularUser")', document: nil do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"RegularUser"}}') }

      example "Update Zip Code" do
        do_request(id: zip_code.id, zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 403
        expect(json_response).to eq(message: "Access Forbidden")
      end
    end

    context "Admin User" do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"AdminUser"}}') }

      example "Update Zip Code by Admin" do
        do_request(id: zip_code.id, zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 200
        expect(json_response[:zip_code].values_at(:zip, :street_name, :building_number, :city, :state)).to eq(
          valid_attributes.values_at(:zip, :street_name, :building_number, :city, :state))
        expect(zip_code.reload.attributes.values_at(*valid_attributes.keys.map(&:to_s))).to eq valid_attributes.values
      end

      example "Update Zip Code that does not exist", document: nil do
        do_request(id: 800)

        expect(status).to eq 404
        expect(response_body).to eq '{"message":"Record not found"}'
      end

      example "Update Zip Code provide to big ID number", document: nil do
        do_request(id: 3000000000, zip_code: valid_attributes)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 400
        expect(json_response[:message]).to eq 'Invalid Parameter: id'
        expect(json_response[:errors][:id]).to eq 'Parameter cannot be greater than 2147483647'
      end

      example "Update Zip Code provide not Hash zip_code params", document: nil do
        do_request(id: zip_code.id, zip_code: "STRING")

        expect(status).to eq 200
      end
    end
  end

  delete "/api/v1/zip_codes/:id.json" do
    parameter :id, "Record ID", required: true

    let(:zip_code) { create(:zip_code) }

    context "Public User", document: nil do
      example "Delete Zip Code" do
        do_request(id: zip_code.id)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 403
        expect(json_response).to eq(message: "Access Forbidden")
        expect(ZipCode.where(id: zip_code.id)).to be_present
      end
    end

    context 'Regular User (authenticated user with type "RegularUser")', document: nil do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"RegularUser"}}') }

      example "Delete Zip Code" do
        do_request(id: zip_code.id)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 403
        expect(json_response).to eq(message: "Access Forbidden")
        expect(ZipCode.where(id: zip_code.id)).to be_present
      end
    end

    context "Admin User" do
      header "Authorization", 'OAuth abcdefgh12345678'
      before { FakeWeb.register_uri(:get, "http://localhost:4545/api/v1/users/me.json",
        body: '{"user":{"id":1,"type":"AdminUser"}}') }

      example "Delete Zip Code by Admin" do
        do_request(id: zip_code.id)

        expect(status).to eq 200
        expect(ZipCode.where(id: zip_code.id)).to be_empty
      end

      example "Delete Zip Code that does not exist", document: nil do
        do_request(id: 800)

        expect(status).to eq 404
        expect(response_body).to eq '{"message":"Record not found"}'
      end

      example "Delete Zip Code provide to big ID number", document: nil do
        do_request(id: 3000000000)
        json_response = JSON.parse(response_body, symbolize_names: true)

        expect(status).to eq 400
        expect(json_response[:message]).to eq 'Invalid Parameter: id'
        expect(json_response[:errors][:id]).to eq 'Parameter cannot be greater than 2147483647'
      end
    end
  end
end
```

We have tested all cases when admin user, regular user or public user gets access to the Zip codes service API. Now we can do refactoring with confidence that service will work as expected after changes (if tests will pass after changes).

## Refactoring

We can move ability in separete class - `app/models/ability.rb`, `cancan` (`sinatra-can`) uses this class by default.

```ruby
class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    can :manage, ZipCode if user.type == 'AdminUser'
    can :create, ZipCode if user.type == 'RegularUser'
  end
end
```

And delete ability block from `application.rb`

```ruby
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

# Set up current_user
user do
  if request.env['HTTP_AUTHORIZATION'].present?
    response = Faraday.new("http://localhost:4545/api/v1/users/me.json",
      headers: { 'Authorization' => request.env['HTTP_AUTHORIZATION'] }).get
    halt 401 if response.status == 401 # go to error 401 handler
    OpenStruct.new(JSON.parse(response.body)['user']) if response.success?
  end
end

# Client uses incorrect token
error(401) { '{"message":"Invalid or expired token"}' }

# Operation forbidden (user can be logged in with token or public)
error(403) { '{"message":"Access Forbidden"}' }

error(ActiveRecord::RecordNotFound) { [404, '{"message":"Record not found"}'] }
error(ActiveRecord::RecordInvalid) do
  [422, { message: "Validation errors occurred",
          errors:  env['sinatra.error'].record.errors.messages }.to_json ]
end
error { '{"message":"An internal server error occurred. Please try again later."}' }
```

Also we can use `sinatra-can` `load_and_authorize!` helper to load model by `params[:id]` and authorize in one line.

So we can write this:

```ruby
load_and_authorize! ZipCode
```

Instead this:

```ruby
@zip_code = ZipCode.find(params[:id])
authorize! :update, @zip_code
```

Or this:

```ruby
@zip_code = ZipCode.find(params[:id])
authorize! :destroy, @zip_code
```

But how it will guess for which ability to authorize (update or destroy)? `load_and_authorize!` checks ability according to the HTTP Request Method: PUT for `:update` and DELETE for `destroy`. Also note that `load_and_authorize!` initializes instance variable (name prefixed with `@`).

This is refactored version of `app/controllers/zip_codes_controller.rb`

```ruby
post "/api/v1/zip_codes.json" do
  param :zip_code, Hash
  zip_code = ZipCode.new(params[:zip_code])
  authorize! :create, zip_code
  zip_code.save!
  status 201
  zip_code.to_json
end

get "/api/v1/zip_codes/:zip.json" do
  param :zip, String, format: /\A\d{5}(?:-\d{4})?\Z/
  zip_code = ZipCode.find_by_zip!(params[:zip])
  zip_code.to_json
end

put "/api/v1/zip_codes/:id.json" do
  param :id, Integer, max: 2147483647
  param :zip_code, Hash
  load_and_authorize! ZipCode # load @zip_code and authorize! :update, @zip_code
  @zip_code.update_attributes!(params[:zip_code]) if params[:zip_code].any?
  @zip_code.to_json
end

delete "/api/v1/zip_codes/:id.json" do
  param :id, Integer, max: 2147483647
  load_and_authorize! ZipCode # load @zip_code and authorize! :destroy, @zip_code
  @zip_code.destroy!
end
```

if record not found `sinatra-can` calls `error(404)` (similar to `halt(404)`) instead throwing `ActiveRecord::RecordNotFound` exception. So we should handle this error as well as `ActiveRecord::RecordNotFound`. In `application.rb` replace line

```ruby
error(ActiveRecord::RecordNotFound) { [404, '{"message":"Record not found"}'] }`
```

with

```ruby
error(404, ActiveRecord::RecordNotFound) { [404, '{"message":"Record not found"}'] }
```

Here is full `application.rb`

```ruby
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
```

Don't forget to run tests.

## Summary

We build remote authentication through `users` service with HTTP client library [faraday](https://github.com/lostisland/faraday). We used [fakeweb](https://github.com/facewatch/fakeweb) for testing remote authentication (emulate `users` service).
We used [sinatra-can](https://github.com/shf/sinatra-can) (which is sinatra wrapper for [cancan](https://github.com/ryanb/cancan)) for authorization.
We have extended Zip codes service with 401 and 403 HTTP status codes (and error messages).
