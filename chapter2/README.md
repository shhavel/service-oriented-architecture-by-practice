Chapter #2. Database Managment and General Service Structure
============================================================
In this chapter we will create service for simple game Tic Tac Toe (Noughts and Crosses) and we will focus more on service structure and database management tasks, such as create database, creation migration, run migration, rollback migration.

We will store games in relational database (namely postgreSQL but you can use different such as SQLite or MySQL). Game keeps it's board, after create board is empty. Service allows player to make a move on particular game's board after that service makes own move and responds with updated game representation in text format.

Here is representation of empty game's board:

       |   |
    -----------
       |   |
    -----------
       |   |

And here is like it can look after first move:

       |   |
    -----------
     O | X |
    -----------
       |   |

## Service interface.

After we create service player should be able to create game by POSTing on games URL:

    $ curl -X POST "localhost:4567/api/v1/games.txt"
    Game #1
    Status: In Progress

       |   |
    -----------
       |   |
    -----------
       |   |

And make a move by PUTing game attributes on specific game URL:

    $ curl -X PUT "localhost:4567/api/v1/games/1.txt?game%5Bmove%5D=4"
    Game #1
    Status: In Progress

       |   |
    -----------
     O | X |
    -----------
       |   |

Service responds with own move and notifies about game status: "In Progress", "Won", "Lost", "Draw". Note that player provides a HASH of game params, in this case it is GET params (part of URL), but actually should be POST params (provided in HTTP request body) - we stay for awhile with GET params for some simplicity. URL length is limited depending on your web server, so in general we should use POST. Game's HASH contains only one key - move, and it's value is number of cell in with player wants to place cross - "X" (cell should be empty). If game is not finished after player's move computer puts "O" on empty cell. Cells are numbered from 0 till 9 (this is not rules this is our representation of cells mixed with way to make a move):

     0 | 1 | 2
    -----------
     3 | 4 | 5
    -----------
     6 | 7 | 8

If game is not finished player can make another move. Game considered finished it is won or lost or there are no empty cells anymore. Game considerd won (by player) if there are three crosses on board are placed on one line (horizontal, vertical or diagonal). Game considerd lost (by player) if there are three noughts on board are placed on one line (horizontal, vertical or diagonal).

## Game's model interface.

## Add custom rake task
