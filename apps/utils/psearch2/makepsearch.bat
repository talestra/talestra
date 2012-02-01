@echo off
REM tcc psearch.c %*
dmd psearch.d %*
copy psearch.exe \util\bin\psearch.exe
copy psearch.exe \projects\toa-spa\text\psearch.exe