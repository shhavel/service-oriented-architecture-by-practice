require "active_resource"

class ZipCode < ActiveResource::Base
  self.format = :json
  self.include_root_in_json = true 
  self.site = "http://localhost:4567"
  self.prefix = "/api/v1/"
end

# get Zip code from http://localhost:4567/api/v1/zip_codes/401.json
zip_code = ZipCode.find(401)
zip_code.zip # => "63109" 
zip_code.street_name # => "Candido Loop" 
zip_code.building_number # => "897" 
zip_code.city # => "New Hoyt" 
zip_code.state # => "Utah"

# get zip codes list from http://localhost:4567/api/v1/zip_codes.json
zip_codes = ZipCode.find(:all)
zip_codes = ZipCode.find(:all, params: { state_eq: "Massachusetts" })
zip_codes = ZipCode.find(:all, params: { zip_start: "119" })
# request list, but return only one
zip_codes = ZipCode.find(:first, params: { zip_start: "119" })

# update Zip code
ZipCode.headers["Authorization"] = "OAuth 562f9fdef2c4384e4e8d59e3a1bcb74fa0cff11a75fb9f130c9f7a146a003dcf"
zip_code.city = "New Johnathan"
zip_code.save

# delete zip_code
zip_code = ZipCode.find(101186)
zip_code.destroy

# create Zip Code
zip_code = ZipCode.create(zip: "82470-2132", street_name: "Micheal Street",
  building_number: "911", city: "South Madalyn", state: "Louisiana")

zip_code.id # => 101187 
