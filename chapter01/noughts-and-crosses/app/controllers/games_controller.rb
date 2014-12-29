get "/api/v1/games/:id.txt" do
  @game = Game.find(params[:id])
  @game.board
end

post "/api/v1/games.txt" do
  @game = Game.create
  status 201
  @game.board
end

put "/api/v1/games/:id.txt" do
  @game = Game.find(params[:id])
  @game.update_attributes!(params[:game])
  @game.board
end
