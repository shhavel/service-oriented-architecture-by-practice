require_relative "../service"
require "rack/test"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end

describe "Divisor Service" do
  describe "GET /api/v1/ratio/:a/:b" do
    it "calculates the ratio of two numbers and returns decimal representation of the ratio" do
      get "/api/v1/ratio/3/4"
      expect(last_response).to be_ok
      expect(last_response.body).to eq "0.75"
    end
  end
end
