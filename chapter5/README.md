Chapter #5. JSON Web Services
=============================

Web services can use different formats for data serialization. The most common are XML and JSON. JSON is simple and it is great for JavaScript application clients (Front End, which is running in a web browser). One of the limitations in the use of JSON is that with JSON you do not specify data types (such as String, Integer, Array). So client should guess data type by data itself. For most cases it is obvious and is handled by JSON parser. Date types (that is string in JSON) you can handle with some other option: check all values that match date-time regular expression and convert them, or convert only values of predefined list of keys (you should know from somewhere all keys that hold date-time values).

In few next chapters we will build ZIP codes web service for serving US postcodes. In this chapter we will create service that serialize data in json and parse JSON date from requests.

## Create ZIP codes service structure

OK, create plese `zip_codes` folder somewhere in your system. Create folders `app`, `config`, `db`, `doc`, `log`, `script`, `spec`. Create folders `models` and `controllers` inside folder `app` and create folders `acceptance`, `factories`, `models` inside folder `spec`. Create file `config/database.yml` with your database settings, here is mine:

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: zipcodes_development
  username: alex

test:
  adapter: postgresql
  encoding: unicode
  database: zipcodes_test
  username: alex
```
Create file `script/console`

```ruby
#!/bin/bash

# parameter: RACK_ENV
bundle exec irb -r ./application.rb
```

And make it executable (on UNIX system):

    $ chmod +x script/console

Create file `spec/spec_helper.rb`

```ruby
ENV['RACK_ENV'] = 'test'
require File.expand_path("../../application", __FILE__)

FactoryGirl.find_definitions

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

Note that we have updated configurations for `rspec_api_documentation` gem. Option `curl_host` is important, if it is set documentation will contain curl example which is often useful for debugging web services.

If you are using git add file `.gitignore` inside `zip_codes`.

    log/*.log
    doc/*

And also you can add emty file named `.keep` (or `.gitkeep`) inside folders `log`, `doc`, and `lib/tasks` (we did not create last one).

Create file `Gemfile` inside `zip_codes`

```ruby
source 'https://rubygems.org'

gem 'rake'
gem 'sinatra', require: 'sinatra/main'
gem 'rack-contrib', git: 'https://github.com/rack/rack-contrib'
gem 'pg'
gem 'activerecord'
gem 'protected_attributes'
gem 'sinatra-activerecord'

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
end
```

And run

    $ bundle install

Create file `Rakefile`

```ruby
require_relative 'application'
require 'sinatra/activerecord/rake'

unless ENV['RACK_ENV'].to_s == 'production'
  require 'rspec_api_documentation'
  load 'tasks/docs.rake'
end
```

Create file `application.rb` inside `zip_codes`

```ruby
require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }

Dir[File.join(settings.root, "app/{models,controllers}/*.rb")].each { |f| require f }
```

You cam also create file `.rspec` with configs for rspec

    --color
    --require spec_helper

Line `--require spec_helper` automatically requires file `spec_helper.rb` in all spec files. So you can omit explicit `require "spec_helper"` in each spec file. (We will add it anyway).

Here if created service structure

![Basic gem structure](images/zip_codes_structure.png)

## Create databases

If you have not created development and test databases yet run `rake db:create` (in terminal from `zip_codes` dir). This will create both databases.

## Create model and migration

We will create one model for ZIP codes with five attributes: zip, street name, building number, city, state. All attributes are strings. Attribute zip is mandatory (cann't be empty) and should be validated with next regular expression: `/\A\d{5}(?:-\d{4})?\Z/` (5 digits or 9 digits with minus char after 5th digit).

Create please migration with next task:

    $ rake db:create_migration NAME=create_zip_codes

Apply it's code (file created `db/migrate` folder)

```ruby
class CreateZipCodes < ActiveRecord::Migration
  def change
    create_table :zip_codes do |t|
      t.string :zip, null: false
      t.string :street_name
      t.string :building_number
      t.string :city
      t.string :state

      t.timestamps null: false
    end

    add_index :zip_codes, :zip
  end
end
```

Run migration for both development and test databases

    $ rake db:migrate
    $ RACK_ENV=test rake db:migrate

Now we can create model - file `app/models/zip_code.rb`

```ruby
class ZipCode < ActiveRecord::Base
  validates :zip, presence: true
  validates_format_of :zip, with: /\A\d{5}(?:-\d{4})?\Z/

  attr_accessible :zip, :street_name, :building_number, :city, :state
end
```

And model tests - file `spec/models/zip_code_spec.rb`

```ruby
describe ZipCode do
  describe "validations" do
    it { should validate_presence_of(:zip) }

    it { is_expected.to allow_value('12345').for(:zip) }
    it { is_expected.to allow_value('12345-1234').for(:zip) }
    it { is_expected.not_to allow_value('123ab').for(:zip) }
    it { is_expected.not_to allow_value('123456').for(:zip) }
    it { is_expected.not_to allow_value('12345-123').for(:zip) }
  end

  describe 'assignament' do
    it { is_expected.not_to allow_mass_assignment_of(:id) }
    it { is_expected.to allow_mass_assignment_of(:zip) }
    it { is_expected.to allow_mass_assignment_of(:street_name) }
    it { is_expected.to allow_mass_assignment_of(:building_number) }
    it { is_expected.to allow_mass_assignment_of(:city) }
    it { is_expected.to allow_mass_assignment_of(:state) }
  end
end
```

Now we have model test that you can run with `rspec` command.

Create please file `spec/factories/zip_codes.rb` with factory for creating Zip codes in tests. We will use it shortly in acceptance tests.


```ruby
FactoryGirl.define do
  factory :zip_code do
    zip { Faker::Address.zip }
    street_name { Faker::Address.street_name }
    building_number { Faker::Address.building_number }
    city { Faker::Address.city }
    state { Faker::Address.state }
  end
end
```

We have used gem [faker](https://github.com/stympy/faker) for generating different fake Zip code attributes.

## Top-level interface planning

## Create controller

