require "sinatra/main"

get "/api/v1/ratio/:a/:b" do
  content_type :txt
  "#{params[:a].to_f / params[:b].to_f}"
end
