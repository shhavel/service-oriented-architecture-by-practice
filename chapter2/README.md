Chapter #2. Database Managment and General Service Structure
============================================================
In this chapter we will create service for simple game Tic Tac Toe (Noughts and Crosses) and we will focus more on service structure and database management tasks, such as create database, creation migration, run migration, rollback migration.

We will store games in relational database (namely postgreSQL but you can use different such as SQLite or MySQL). Game keeps it's board, after create board is empty. Service allows player to make a move on particular game's board after that service makes own move and responds with updated game representation in text format.

Here is representation of empty game's board:

       |   |
    -----------
       |   |
    -----------
       |   |

And here is like it can look after first move:

       |   |
    -----------
     O | X |
    -----------
       |   |

## Service interface.

After we create service player should be able to create game by POSTing on games URL:

    $ curl -X POST "localhost:4567/api/v1/games.txt"
    Game #1
    Status: In Progress

       |   |
    -----------
       |   |
    -----------
       |   |

And make a move by PUTing game attributes on specific game URL:

    $ curl -X PUT "localhost:4567/api/v1/games/1.txt?game%5Bmove%5D=4"
    Game #1
    Status: In Progress

       |   |
    -----------
     O | X |
    -----------
       |   |

Service responds with own move and notifies about game status: "In Progress", "Won", "Lost", "Draw". Note that player provides a HASH of game params, in this case it is GET params (part of URL), but actually should be POST params (provided in HTTP request body) - we stay for awhile with GET params for some simplicity. URL length is limited depending on your web server, so in general we should use POST. Game's HASH contains only one key - move, and it's value is number of cell in with player wants to place cross - "X" (cell should be empty). If game is not finished after player's move computer puts "O" on empty cell. Cells are numbered from 0 till 9 (this is not rules this is our representation of cells mixed with way to make a move):

     0 | 1 | 2
    -----------
     3 | 4 | 5
    -----------
     6 | 7 | 8

If game is not finished player can make another move. Game considered finished it is won or lost or there are no empty cells anymore. Game considerd won (by player) if there are three crosses on board are placed on one line (horizontal, vertical or diagonal). Game considerd lost (by player) if there are three noughts on board are placed on one line (horizontal, vertical or diagonal).

## Game's model interface.

Our game model should behave like this:

```ruby
# created new game with empty board.
game = Game.create

# Game has it's own unique ID
game.id

# making a move (computer makes countermove and saves record into database)
game.update_attributes(move: 4)

# Game status: "In Progress", "Won", "Lost", "Drow"
gmae.status

# Array of board cells: each value equals one of strings "X", "O" or ""
game.cells
```

## Create skeleton of the service

Create please `noughts-and-crosses` forler and file named `Gemfile` in it with list of needed gems:

```ruby
source 'https://rubygems.org'

gem 'rake'
gem 'sinatra'
gem 'pg'
gem 'activerecord'
gem 'protected_attributes'
gem 'sinatra-activerecord'

group :development, :test do
  gem 'thin'
  gem 'pry-debugger'
end

group :test do
  gem 'rspec'
  gem 'shoulda'
  gem 'factory_girl'
  gem 'database_cleaner'
  gem 'rack-test'
end
```

In terminal navigate to `noughts-and-crosses` folder and run `bundle install`. We split gems into groups: some of them needed only for testing, some only for testing and development. Note gem `sinatra-activerecord` - it is used for automatically establishing database connection by configure file and for database management rake tasks.

Now create file `application.rb` in `noughts-and-crosses` folder, this would be main service file.

```ruby
require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"

set :root, File.dirname(__FILE__)
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }

Dir[File.join(settings.root, "app/models/*.rb")].each do |f|
  autoload File.basename(f, '.rb').classify.to_sym, f
end
Dir[File.join(settings.root, "app/controllers/*.rb")].each { |f| require f }

before do
  content_type :txt
end

error(ActiveRecord::RecordNotFound) { [404, "There is no Game with provided id"] }
error(ActiveRecord::RecordInvalid) { [422, env['sinatra.error'].record.errors.full_messages.join("\n")] }
error { "An internal server error occurred. Please try again later." }
```

Let's walk through it by small bits

```ruby
require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
puts "Loaded #{Sinatra::Application.environment} environment"
```

Here we are requirung all games of specific environments. We can run service in different environments by passing RACK_ENV. By default environment is `development`.

    RACK_ENV=production ruby application.rb

Set service root.

```ruby
set :root, File.dirname(__FILE__)
```

Then we can refer to it as `settings.root`.

Setup access logger:

```ruby
use Rack::CommonLogger, File.new(File.join(settings.root, 'log',
  "#{settings.environment}.log"), 'a+').tap { |f| f.sync = true }
```

We should create log folder inside `noughts-and-crosses` folder. If we use git we might want to create file `.gitignore` in `noughts-and-crosses` folder with next content.

    log/*.log

This prevents the log files in the repository. Also we can create empty file `.gitkeep` or just `.keep` inside `log` folder to ensure that empty log folder to be in repo(sitory).

Next. We will keep our model class files inside `models` dir inside `app` dir (that is inside `noughts-and-crosses` dir). And we autoload all this files. This means file will actually loaded in memory only after first attempt to use class. Also we will keep all routes in `app/controllers` folder. All routes related to one model will be in one file. And in one file will be routes related to only one model.

```ruby
Dir[File.join(settings.root, "app/models/*.rb")].each do |f|
  autoload File.basename(f, '.rb').classify.to_sym, f
end
Dir[File.join(settings.root, "app/controllers/*.rb")].each { |f| require f }
```

In this service we will only have one model - `Game` and that is why only one controller.

Content type of responses will be plain text. "Content-Type: text/html" header is provided for this.

```ruby
before do
  content_type :txt
end
```

And handle some errors and respond with appropriate HTTP code. 404 - for record no found, and 422 - for validation errors.

```ruby
error(ActiveRecord::RecordNotFound) { [404, "There is no Game with provided id"] }
error(ActiveRecord::RecordInvalid) { [422, env['sinatra.error'].record.errors.full_messages.join("\n")] }
error { "An internal server error occurred. Please try again later." }
```

Last one line handles all other unexpected errors and responds with 500 HTTP code.

Now plese create folders `app/models`, `app/controllers`. Create folder `config` inside `noughts-and-crosses` with file `database.yml` in it. This file will be used by gem `sinatra-activerecord` by default. Here is my configuration (change username in it):

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: noughts_and_crosses_development
  username: alex

test:
  adapter: postgresql
  encoding: unicode
  database: noughts_and_crosses_test
  username: alex
```

Create folder `db` inside root folder and folder `migrate` inside `db`. Create folder `spec` for tests, file `spec_helper.rb`, folders `acceptance`, `factories`, `models` in it.

Here is `spec_helper.rb`

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
```

And here is all service structure for a while ![Basic gem structure](images/noughts_and_crosses_structure.png)

## Create migration

## Create model

Game realisation is not really significant, because we are focusing more on top behaviour. Anyway here is my representation of game class (file `app/models/game.rb`).

```ruby

```

## Create controller and acceptance tests

## Create console

## Add custom rake task
