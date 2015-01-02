require_relative "../service"
require "rack/test"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.after(:each) { Note.delete_all }

  def app
    Sinatra::Application
  end
end

describe "Notes Service" do
  describe "POST /api/v1/notes.txt" do
    let(:note) { Note.last }

    it "craetes new note" do
      post "/api/v1/notes.txt", content: "My New Note"
      expect(last_response.status).to eq 201
      expect(last_response.body).to eq "##{note.id} My New Note"
    end
  end

  describe "GET /api/v1/notes.txt" do
    before { Note.create([{ id: 1, content: "First Note" }, { id: 2, content: "Second Note" }]) }

    it "retrieves all notes" do
      get "/api/v1/notes.txt"
      expect(last_response).to be_ok
      expect(last_response.body).to eq "#1 First Note\n#2 Second Note"
    end
  end

  describe "GET /api/v1/notes/:id.txt" do
    before { Note.create([{ id: 4, content: "My Note" }]) }

    it "retrieves specific note" do
      get "/api/v1/notes/4.txt"
      expect(last_response).to be_ok
      expect(last_response.body).to eq "#4 My Note"
    end
  end

  describe "PUT /api/v1/notes/:id.txt" do
    before { Note.create([{ id: 4, content: "My Note" }]) }

    it "updates note and returns updated content" do
      put "/api/v1/notes/4.txt", content: "New Content"
      expect(last_response).to be_ok
      expect(last_response.body).to eq "#4 New Content"
      expect(Note.last.content).to eq "New Content"
    end
  end

  describe "DELETE /api/v1/notes/:id.txt" do
    before { Note.create([{ id: 4, content: "My Note" }]) }

    it "deletes note" do
      delete "/api/v1/notes/4.txt"
      expect(last_response).to be_ok
      expect(Note.last).to be_nil
    end
  end
end
