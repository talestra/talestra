module complib;

import std.stream, std.file, std.string, std.stdio;

//pragma(lib, "complib.obj");

T abs(T)(T v) { return (v >= 0) ? v : -v; }

enum Error : int {
	SUCCESS               =  0,
	ERROR_FILE_IN         = -1,
	ERROR_FILE_OUT        = -2,
	ERROR_MALLOC          = -3,
	ERROR_BAD_INPUT       = -4,
	ERROR_UNKNOWN_VERSION = -5,
	ERROR_FILES_MISMATCH  = -6,
}

class CompressionException : Exception {
	static string ErrorString(Error error) {
		switch (error) {
			case Error.SUCCESS               : return "Success";
			case Error.ERROR_FILE_IN         : return "File In";
			case Error.ERROR_FILE_OUT        : return "File Out";
			case Error.ERROR_MALLOC          : return "Malloc";
			case Error.ERROR_BAD_INPUT       : return "Bad Input";
			case Error.ERROR_UNKNOWN_VERSION : return "Unknown Version";
			case Error.ERROR_FILES_MISMATCH  : return "Files Mismatch";
			default: return "Unknown error";
		}
	}

	this(string s) { super(s); }
	this(Error error) { super(ErrorString(error)); }
}

extern (C) {
	char *GetErrorString(int error);
	Error Encode(int _version, void *_in, int inl, void *_out, uint *outl);
	Error Decode(int _version, void *_in, int inl, void *_out, uint *outl);
}

void EnforceError(Error error) {
	if (error != Error.SUCCESS) throw(new CompressionException(error));
}

ubyte[] compress(ubyte[] uncompressed, int _version) {
	ubyte[] compressed = new ubyte[((uncompressed.length * 9) / 8) + 16];
	uint compressed_length = compressed.length;
	EnforceError(Encode(
		_version,
		uncompressed.ptr,
		uncompressed.length,
		compressed.ptr,
		&compressed_length
	));
	compressed.length = compressed_length;
	return compressed;
}

ubyte[] decompress(ubyte[] compressed, int _version, int exected_uncompressed_size = 0) {
	ubyte[] uncompressed = new ubyte[(exected_uncompressed_size != 0) ? exected_uncompressed_size : (compressed.length * 13)];
	uint uncompressed_length = uncompressed.length;
	EnforceError(Decode(
		_version,
		compressed.ptr,
		compressed.length,
		uncompressed.ptr,
		&uncompressed_length
	));
	uncompressed.length = uncompressed_length;
	return uncompressed;
}

align(1) struct Header {
	ubyte _version;
	uint size_compressed;
	uint size_uncompressed;
}

ubyte[] decompressWithHeader(ubyte[] data) {
	auto header = *cast(Header *)data.ptr;
	auto compressed_block = data[1 + 4 + 4..$];
	assert(compressed_block.length >= header.size_compressed);
	return decompress(compressed_block, header._version, header.size_uncompressed);
}

ubyte[] compressWithHeader(ubyte[] uncompressed, int _version) {
	Header header;
	auto compressed = compress(uncompressed, _version);
	header._version = abs(_version);
	//writefln("%d,%d", abs(_version), _version);
	header.size_compressed   = compressed.length;
	header.size_uncompressed = uncompressed.length;
	return cast(ubyte[])((&header)[0..1]) ~ compressed;
}

unittest {
	scope test = cast(ubyte[])"Hola, esto es una prueba. Hola, esto es otra prueba.";
	assert(test == decompressWithHeader(compressWithHeader(test, 3)), "Compression with header fails");
	//writefln("compression with header");
}