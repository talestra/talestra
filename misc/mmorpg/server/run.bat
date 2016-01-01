@echo off
..\..\bin\dmd\windows\bin\dmd mmorpg\util.d mmorpg\net\packet.d mmorpg\cards.d imports.d -run main.d
REM ..\..\bin\dmd\windows\bin\dmd sqlite3.lib sqlite3.d mmorpg\util.d mmorpg\net\packet.d mmorpg\cards.d -run main.d
REM dmd -v1 mmorpg\util sqlite3 mmorpg\net\packet mmorpg\cards -run main
