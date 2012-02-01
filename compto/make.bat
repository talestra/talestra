@\dev\tcc\tcc.exe complib.c compto.c -o ..\comptoe.exe
@upx.exe ..\comptoe.exe > NUL 2> NUL
@copy /Y ..\comptoe.exe c:\util\bin\comptoe.exe > NUL 2> NUL

@\dev\tcc\tcc.exe lzx_vesp.c -o lzx_vesp.exe
@upx.exe lzx_vesp.exe > NUL 2> NUL
@copy /Y lzx_vesp.exe c:\util\bin\lzx_vesp.exe > NUL 2> NUL
@copy /Y lzx_vesp.exe ..\lzx_vesp.exe > NUL 2> NUL
