#include <stdio.h>
#include <windows.h>

#define _In_
#define _Out_
#define _Out_opt_
#define _Inout_opt_

INT WINAPI LZOpenFileA(
  _In_   LPTSTR lpFileName,
  _Out_  LPOFSTRUCT lpReOpenBuf,
  _In_   WORD wStyle
);

BOOL WINAPI WriteFile(
  _In_         HANDLE hFile,
  _In_         LPCVOID lpBuffer,
  _In_         DWORD nNumberOfBytesToWrite,
  _Out_opt_    LPDWORD lpNumberOfBytesWritten,
  _Inout_opt_  LPOVERLAPPED lpOverlapped
);

LONG WINAPI LZCopy(
  _In_  INT hfSource,
  _In_  INT hfDest
);

INT WINAPI LZRead(
  _In_   INT hFile,
  _Out_  LPSTR lpBuffer,
  _In_   INT cbRead
);

HFILE WINAPI OpenFile(
  _In_   LPCSTR lpFileName,
  _Out_  LPOFSTRUCT lpReOpenBuff,
  _In_   UINT uStyle
);

INT WINAPI LZInit(
  _In_  INT hfSource
);

void APIENTRY LZClose(
  _In_  INT hFile
);


DWORD WINAPI GetFileSize(
  _In_       HANDLE hFile,
  _Out_opt_  LPDWORD lpFileSizeHigh
);

LONG WINAPI LZSeek(
  _In_  INT hFile,
  _In_  LONG lOffset,
  _In_  INT iOrigin
);


OFSTRUCT file2;
int hFile2;
FILE *f;

void main() {
	char *buffer;
	int size;
	hFile2 = LZOpenFileA("P_CURSOR.CRP", &file2, OF_READ);
	LZInit(hFile2);
	size = LZSeek(hFile2, 0, SEEK_END);
	LZSeek(hFile2, 0, SEEK_SET);
	printf("%d\n", size);
	buffer = (char *)malloc(size);
	LZRead(hFile2, buffer, size);
	LZClose(hFile2);
	
	f = fopen("P_CURSOR.CRP.u2", "wb");
	fwrite(buffer, size, 1, f);
	fclose(f);
}