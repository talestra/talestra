@echo off
rcc.exe -32 resource.rc
dfl.exe main.d opengl.d util.d ase.d npc.d rpx.d txd.d resource.res -oftoamv.exe
del toamv.obj
del toamv.map
REM del toamv.exe