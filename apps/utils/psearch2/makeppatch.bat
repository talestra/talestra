@echo off
dmd ppatch.d %*
copy ppatch.exe \util\bin\ppatch.exe
