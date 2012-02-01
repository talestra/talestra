#ifndef __COMPLIB_H
	#define __COMPLIB_H

	#define SUCCESS                0
	#define ERROR_FILE_IN         -1
	#define ERROR_FILE_OUT        -2
	#define ERROR_MALLOC          -3
	#define ERROR_BAD_INPUT       -4
	#define ERROR_UNKNOWN_VERSION -5
	#define ERROR_FILES_MISMATCH  -6
	
	#define LZAPI __declspec(dllexport) 

	LZAPI char *GetErrorString(int error);
	LZAPI int Encode(int version, void *in, int inl, void *out, unsigned int *outl);
	LZAPI int Decode(int version, void *in, int inl, void *out, unsigned int *outl);
	LZAPI int DecodeFile(char *in, char *out, int raw, int version);
	LZAPI int EncodeFile(char *in, char *out, int raw, int version);
	LZAPI int DumpTextBuffer(char *out);

	LZAPI int CheckCompression(char *in, int version);
	
	// Non-Thread Safe
	LZAPI void ProfileStart(char *out);
	LZAPI void ProfileEnd();

#endif
