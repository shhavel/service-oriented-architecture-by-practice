Users Service
=============

This is modified version of service for Chapter #10 - added timeout delay 15 seconds

## Running web service

    $ ruby service.rb

## Retrieve user

    $ curl -X GET "localhost:4567/api/v1/users/me.json" \
    $ -H "Authorization: OAuth b259ca1339e168b8295287648271acc94a9b3991c608a3217fecc25f369aaa86"

    {"user":{"type":"RegularUser"}}
