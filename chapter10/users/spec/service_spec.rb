require "spec_helper"

describe "Users Service" do
  describe "GET /api/v1/users/me.json" do
    it "retrieves admin user JSON representation of provided token of admin user" do
      header "Authorization", "OAuth 562f9fdef2c4384e4e8d59e3a1bcb74fa0cff11a75fb9f130c9f7a146a003dcf"
      get "/api/v1/users/me.json"
      expect(last_response).to be_ok
      expect(last_response.body).to eq '{"user":{"type":"AdminUser"}}'
    end

    it "retrieves regular user JSON representation of provided token of regular user" do
      header "Authorization", "OAuth b259ca1339e168b8295287648271acc94a9b3991c608a3217fecc25f369aaa86"
      get "/api/v1/users/me.json"
      expect(last_response).to be_ok
      expect(last_response.body).to eq '{"user":{"type":"RegularUser"}}'
    end

    it "responds with 401 status and JSON error message if access token expired or incorrect" do
      header "Authorization", "OAuth 7564e5ab2d46d5af38e99e5490eea2c86b96f6a638d77fa0b124125ed26347eb"
      get "/api/v1/users/me.json"
      expect(last_response.status).to eq 401
      expect(last_response.body).to eq '{"message":"Invalid or expired token"}'
    end

    it "responds with 403 status and JSON error message if access token not provided" do
      get "/api/v1/users/me.json"
      expect(last_response.status).to eq 403
      expect(last_response.body).to eq '{"message":"Access Forbidden"}'
    end
  end
end
