Zip Code Service
================

## Running users service (which used for authentication)

    $ ruby service.rb

## Running web service

    $ ruby application.rb

## Create Zip code

    $ curl "http://localhost:4567/api/v1/zip_codes.json" \
      -X POST \
      -H "Authorization: OAuth b259ca1339e168b8295287648271acc94a9b3991c608a3217fecc25f369aaa86" \
      -H "Content-Type: application/json" \
      -d '{"zip_code":{"zip":"89608","street_name":"Shyann Roads","building_number":"67534","city":"West Nickolasfort","state": "Massachusetts"}}'

    {"zip_code":{"id":101188,"zip":"89608","street_name":"Shyann Roads","building_number":"67534","city":"West Nickolasfort","state":"Massachusetts","created_at":"2015-02-20T15:15:37.328Z","updated_at":"2015-02-20T15:15:37.328Z"}}

## Get Zip codes list

    $ curl "http://localhost:4567/api/v1/zip_codes.json" \
      -X GET

    [{"zip_code":{"id":402,"zip":"40664-8387","street_name":"Wuckert Mall","building_number":"2294","city":"New Aiyanatown","state":"Wyoming","created_at":"2015-02-15T09:02:25.383Z","updated_at":"2015-02-15T09:02:25.383Z"}},{"zip_code":{"id":403,"zip":"98189-4795","street_name":"Lucie Falls"...

## Get single Zip code

    $ curl "http://localhost:4567/api/v1/zip_codes/401.json" \
      -X GET

    {"zip_code":{"id":401,"zip":"63109","street_name":"Candido Loop","building_number":"897","city":"New Hoyt","state":"Utah","created_at":"2015-02-15T09:02:25.374Z","updated_at":"2015-02-20T10:48:59.680Z"}}

## Update few attributes (`street_name` and `building_number`) of Zip code

    $ curl "http://localhost:4567/api/v1/zip_codes/401.json" \
      -X PUT \
      -H "Authorization: OAuth 562f9fdef2c4384e4e8d59e3a1bcb74fa0cff11a75fb9f130c9f7a146a003dcf" \
      -H "Content-Type: application/json" \
      -d '{"zip_code":{"street_name":"Wuckert Mall","building_number":"2294"}}'

    {"zip_code":{"id":401,"zip":"63109","street_name":"Wuckert Mall","building_number":"2294","city":"New Hoyt","state":"Utah","created_at":"2015-02-15T09:02:25.374Z","updated_at":"2015-02-20T13:19:52.762Z"}}

## Delete Zip code

    $ curl "http://localhost:4567/api/v1/zip_codes/101132.json" \
      -X DELETE \
      -H "Authorization: OAuth 562f9fdef2c4384e4e8d59e3a1bcb74fa0cff11a75fb9f130c9f7a146a003dcf"
