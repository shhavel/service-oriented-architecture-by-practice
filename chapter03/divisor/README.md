Divisor Service
===============

## Running web service

    $ ruby service.rb

## Compute the result of integer division of two integers

    $ curl -i -X GET "localhost:4567/api/v1/ratio/23/4"
    HTTP/1.1 200 OK
    Content-Type: text/plain;charset=utf-8
    Content-Length: 1
    X-Content-Type-Options: nosniff
    Connection: keep-alive
    Server: thin

    5

## Unexpected errors handling

    $ curl -i -X GET "localhost:4567/api/v1/ratio/1/0"
    HTTP/1.1 500 Internal Server Error
    Content-Type: text/plain;charset=utf-8
    Content-Length: 58
    X-Content-Type-Options: nosniff
    Connection: keep-alive
    Server: thin

    An internal server error occurred. Please try again later.
