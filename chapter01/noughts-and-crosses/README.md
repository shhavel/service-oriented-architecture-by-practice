Noughts and Crosses (Tic Tac Toe) game as RESTful Web Service
=============================================================

## Running web service 

    $ rackup -p 4567

## Create new game

    $ curl -X POST "localhost:4567/api/v1/games.txt"
    Game #1
    Status: In Progress

       |   |  
    -----------
       |   |  
    -----------
       |   |  

## Update game - make a move

Cells are numbered from 0 to 8. For making move provide `game[move]` param which represents the number of one of the empty cells.
Computer will make a countermove if game is not finished.

    $ curl -X PUT "localhost:4567/api/v1/games/1.txt?game%5Bmove%5D=4"
    Game #1
    Status: In Progress

       |   |  
    -----------
     O | X |  
    -----------
       |   |  

    $ curl -X PUT "localhost:4567/api/v1/games/1.txt?game%5Bmove%5D=2"
    Game #1
    Status: In Progress

       |   | X
    -----------
     O | X |  
    -----------
     O |   |  

## Get game

    $ curl -X GET "localhost:4567/api/v1/games/1.txt"
    Game #1
    Status: In Progress

       |   | X
    -----------
     O | X |  
    -----------
     O |   |  


## Play more - update game

    $ curl -X PUT "localhost:4567/api/v1/games/1.txt?game%5Bmove%5D=0"
    Game #1
    Status: In Progress

     X |   | X
    -----------
     O | X |  
    -----------
     O |   | O

    $ curl -X PUT "localhost:4567/api/v1/games/1.txt?game%5Bmove%5D=1"
    Game #1
    Status: Won

     X | X | X
    -----------
     O | X |  
    -----------
     O |   | O
