Chapter #1. Outline
===============
Let's build a simple Web service for managing notes to get more familiar with some technologies that are used is this book and of course to understand partial concepts of Web services.

We will keep notes in sqlite database and allow access and manage those notes via http using incipient just now new notes service. There are some choices of technologies for build service like `rails-api`, `sinatra`, `grape` or combination of this. For all services in this book we will use `sinatra`, generally this is matter of taste - `sinatra` is concise and fits well.

Please create `notes` folder in which will store our service's code files. We need install three ruby gems for managing service internals, thouse are `sinatra`, `sqlite3` and `activerecord` and two gems for testing: `rspec` and `rack-test`.
Create file named `Gemfile` in `notes` folder with next contennts.

```ruby
source 'https://rubygems.org'

gem 'sinatra'
gem 'sqlite3'
gem 'activerecord'
gem 'rspec'
gem 'rack-test'
```

Then in terminal navigate to `notes` folder and run `bundle install` (ruby, ruby gems and gem `bundler` should be intalled for this). This installs all of the above gems and also creates file `Gamfile.lock` with used versions of gems. You should see something similar.

    $ bundle install
    Fetching gem metadata from https://rubygems.org/.........
    Installing i18n (0.7.0)
    Installing json (1.8.2)
    Installing minitest (5.5.1)
    Using thread_safe (0.3.4)
    Installing tzinfo (1.2.2)
    Installing activesupport (4.2.0)
    Using builder (3.2.2)
    Installing activemodel (4.2.0)
    Installing arel (6.0.0)
    Installing activerecord (4.2.0)
    Using diff-lcs (1.2.5)
    Installing rack (1.6.0)
    Installing rack-protection (1.5.3)
    Installing rack-test (0.6.3)
    Installing rspec-support (3.1.2)
    Installing rspec-core (3.1.7)
    Installing rspec-expectations (3.1.2)
    Installing rspec-mocks (3.1.3)
    Installing rspec (3.1.0)
    Using tilt (1.4.1)
    Installing sinatra (1.4.5)
    Installing sqlite3 (1.3.10)
    Using bundler (1.5.3)
    Your bundle is complete!
    Use `bundle show [gemname]` to see where a bundled gem is installed.

Installations part is over. Now we can start developing our service. Please create file `service.rb` in `notes` folder and require three needed gems.

```ruby
require "sqlite3"
require "active_record"
require "sinatra/main"
```

Note that gem is clalled `activerecord` but we have just required `active_record`. And also only part of sinatra but this is not really important.

Than we need to create a database table to sore the notes. Add this please in `service.rb`.

```ruby
class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string :content, null: false, default: 'Empty'
    end
  end
end
```

Table is called `notes` (not surprisingly) and has only one field - content of type text with default value "Empty".

We need to create corresponding ORM class for managing notes records. This is simple - just inherit it from ActiveRecord::Base and class will find `notes` table by its own name (downcase and pluralize word "Note").

```ruby
class Note < ActiveRecord::Base
end
``

Establish connection.

```ruby
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/notes.sqlite3')
```

Create `notes` table if it is not exist - run migration.

```ruby
CreateNotes.new.change unless ActiveRecord::Base.connection.table_exists? :notes
```

That was setup infrastructure code.

Any operation that may be expected from your application can be performed with the four operations: `C`raate some entity, `R`ead entity, `U`pdate entity and `D`elete entity (`CRUD`). This actions are coupled with four (or about four) HTTP verbs: POST, GET, PUT (can be PATCH), DELETE. And URL of the entilty or representation that service users will see in HTTP response (if of course at least one of them will perform a successful HTTP request) is expected to be somehow associated with entity general name which is "notes" in our case. This is genial simplicity of the REST principles.

We also adding prefix "api" to URLs that maybe helpful for users to immediately see that this URLs are part of some API. Also "v1" prefix that can be useful if you will plan maintain several versions of API in future. URLs will end with format that service supports. Let's notes service will supoort text format and URLs will end with ".txt".

We will write code for this four CRUD operations is same order one by one. First is `C`reate.

```ruby
post "/api/v1/notes.txt" do
  content_type :txt
  note = Note.create(content: params[:content])
  status 201
  "##{note.id} #{note.content}"
end
```

sinatra `post` helper creates route for making possible posting records on provided URL - "/api/v1/notes.txt". `content_type :txt` adds HTTP header that notifies client about response format.
