Notes RESTful Web Service
=========================

## Running web service

    $ ruby service.rb

## Create new notes

    $ curl -X POST "localhost:4567/api/v1/notes.txt?content=First%20Note"
    #1 First Note

    $ curl -X POST "localhost:4567/api/v1/notes.txt?content=Second%20Note"
    #2 Second Note

## Retrieve all notes

    $ curl -X GET "localhost:4567/api/v1/notes.txt"
    #1 First Note
    #2 Second Note

## Retrieve specific note

    $ curl -X GET "localhost:4567/api/v1/notes/1.txt"
    #1 First Note

## Update existing note

    $ curl -X PUT "localhost:4567/api/v1/notes/1.txt?content=New%20Content"
    #1 New Content

## Delete note

    $ curl -X DELETE "localhost:4567/api/v1/notes/1.txt"
