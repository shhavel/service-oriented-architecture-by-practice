resource 'ZipCode' do
  header "Accept", "application/json"

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

    example "Create Zip Code" do
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
  end

  get "/api/v1/zip_codes/:zip.json" do
    parameter :zip, "Zip", scope: :zip_code, required: true

    let(:zip_code) { create(:zip_code) }

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

  put "/api/v1/zip_codes/:id.json" do
    header "Content-Type", "application/json"

    parameter :id, "Zip", required: true
    parameter :street_name, "Street name", scope: :zip_code
    parameter :building_number, "Building number", scope: :zip_code
    parameter :city, "City", scope: :zip_code
    parameter :state, "State", scope: :zip_code
    let(:raw_post) { params.to_json }

    let(:zip_code) { create(:zip_code) }
    let(:valid_attributes) { attributes_for(:zip_code) }

    example "Update Zip Code" do
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

    example "Read Zip Code provide to big ID number", document: nil do
      do_request(id: 3000000000, zip_code: valid_attributes)
      json_response = JSON.parse(response_body, symbolize_names: true)

      expect(status).to eq 400
      expect(json_response[:message]).to eq 'Invalid Parameter: id'
      expect(json_response[:errors][:id]).to eq 'Parameter cannot be greater than 2147483647'
    end

    example "Read Zip Code provide not Hash zip_code params", document: nil do
      do_request(id: zip_code.id, zip_code: "STRING")

      expect(status).to eq 200
    end
  end
end
