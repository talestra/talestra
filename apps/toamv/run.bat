@echo off
del toamv.exe > NUL 2> NUL 
cls
call make.bat
toamv.exe
