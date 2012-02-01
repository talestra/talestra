module dcomplib;

private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream, std.gc;
//private import tales.common;

template TSerialize(T) {
	ubyte[] TSerialize(T *t) {
		return (cast(ubyte *)t)[0..T.sizeof];
	}
}

class PatchedMemoryStream : MemoryStream {
	override ulong seek(long offset, SeekPos rel) {
		assertSeekable();
		long scur; // signed to saturate to 0 properly

		switch (rel) {
			case SeekPos.Set: scur = offset; break;
			case SeekPos.Current: scur = cast(long)(cur + offset); break;
			case SeekPos.End: scur = cast(long)(len + offset); break;
			default:
			assert(0);
		}

		if (scur < 0)
			cur = 0;
		// Comportamiento inesperado
		//else if (scur > len)
		//	cur = len;
		else
			cur = cast(ulong)scur;

		return cur;
	}
}

private extern(C) {
	const int SUCCESS               =  0;
	const int ERROR_FILE_IN         = -1;
	const int ERROR_FILE_OUT        = -2;
	const int ERROR_MALLOC          = -3;
	const int ERROR_BAD_INPUT       = -4;
	const int ERROR_UNKNOWN_VERSION = -5;
	const int ERROR_FILES_MISMATCH  = -6;

	char *GetErrorString(int error);
	int   Encode(int ver, void *bin, int inl, void *bout, int *outl);
	int   Decode(int ver, void *bin, int inl, void *bout, int *outl);
	int   DecodeFile(char *bin, char *bout, int raw, int ver);
	int   EncodeFile(char *bin, char *bout, int raw, int ver);
	int   DumpTextBuffer(char *bout);
	void  ProfileStart(char *bout);
	void  ProfileEnd();
	int   CheckCompression(char *bin, int ver);
}

ubyte[] readAll(Stream s) {
	ubyte[] retval;

	if (s.available > 0) {
		retval.length = s.available;
		s.read(retval);
	}

	while (!s.eof) {
		ubyte[0x1000] temp;
		retval ~= temp[0..s.read(temp)];
	}

	return retval;
}

private void DecodeEncodeCheckError(int err) {
	switch (err) {
		case SUCCESS: break;
		case ERROR_FILE_IN:         throw(new Exception("ERROR_FILE_IN"));
		case ERROR_FILE_OUT:        throw(new Exception("ERROR_FILE_OUT"));
		case ERROR_MALLOC:          throw(new Exception("ERROR_MALLOC"));
		case ERROR_BAD_INPUT:       throw(new Exception("ERROR_BAD_INPUT"));
		case ERROR_UNKNOWN_VERSION: throw(new Exception("ERROR_UNKNOWN_VERSION"));
		case ERROR_FILES_MISMATCH:  throw(new Exception("ERROR_FILES_MISMATCH"));
		default: throw(new Exception("Unknown error"));
	}
}

void DecodeStream(Stream fin, Stream fout, bool raw = false, ubyte ver = 3, bool autoclose = false) {
	//int foutp = fout.position, finp = fin.position;

	scope (exit) {
		//fout.position = foutp; fin.position = finp;
		if (autoclose) { fin.close(); fout.close(); }
	}

	uint luncomp, lcomp;
	ubyte[] comp, uncomp;

	if (!raw) {
		fin.read(ver);
		fin.read(lcomp);
		fin.read(luncomp);
	}

	comp = readAll(fin);

	if (luncomp == 0) luncomp = comp.length * 0x12;

	uncomp.length = luncomp;
	comp.length = lcomp;

	DecodeEncodeCheckError(Decode(
		ver,
		comp.ptr,
		cast(int)comp.length,
		uncomp.ptr,
		cast(int *)&luncomp
	));

	uncomp.length = luncomp;

	fout.write(uncomp);

	uncomp.length = comp.length = 0;

	delete comp;
	delete uncomp;

	std.gc.genCollect();
}

public alias DecodeStream Decode;

void EncodeStream(Stream fin, Stream fout, bool raw = false, int ver = 3, bool autoclose = false) {
	//int foutp = fout.position, finp = fin.position;

	scope (exit) {
		//fout.position = foutp; fin.position = finp;
		if (autoclose) { fin.close(); fout.close(); }
	}

	ubyte[] uncomp = readAll(fin), comp;
	uint lcomp;

	lcomp = comp.length = (uncomp.length * 9) / 8;

	DecodeEncodeCheckError(Encode(
		ver,
		cast(void *)uncomp.ptr,
		cast(int)uncomp.length,
		cast(void *)comp.ptr,
		cast(int *)&lcomp
	));

	comp.length = lcomp;

	if (!raw) {
		fout.write(cast(ubyte)ver);
		fout.write(cast(uint)comp.length);
		fout.write(cast(uint)uncomp.length);
	}

	fout.write(comp);

	uncomp.length = comp.length = 0;

	delete comp;
	delete uncomp;

	std.gc.genCollect();
}

public alias EncodeStream Encode;

bool CheckCompression(Stream fin, int ver = 3, bool autoclose = true) {
	scope (exit) { if (autoclose) fin.close(); }

	Stream comp = new MemoryStream();
	Stream uncomp = new MemoryStream();

	Encode(fin, comp, false, ver, false);

	comp.position = 0;
	Decode(comp, uncomp, false, ver, false);

	fin.position = 0; uncomp.position = 0;

	if (readAll(fin) != readAll(uncomp)) {
		throw(new Exception("Compression error"));
	}

	comp.close();
	uncomp.close();

	return true;
}

class CompressedStream : PatchedMemoryStream {
	this(Stream s) {
		//std.stdio.writefln("CompressedStream()");
		DecodeStream(s, this);
		this.position = 0;
	}

	~this() {
		delete buf;
		std.gc.genCollect();
	}

	this(char[] name) {
		File f = new File(name, FileMode.In);
		this(f);
		f.close();
	}
}

class CompressStream : PatchedMemoryStream {
	Stream saves;
	bool raw, closed;
	int ver;

	this(Stream s, int ver = 3, bool raw = false) {
		saves = s;
		this.position = 0;
		this.ver = ver;
		this.raw = raw;
		this.closed = false;
	}

	~this() {
		if (!closed) close();
		delete buf;
	}

	void close() {
		closed = true;
		this.position = 0;
		//void Encode(Stream fin, Stream fout, bool raw = false, int ver = 3, bool autoclose = false)
		EncodeStream(this, saves, raw, ver, false);
		//saves.close();
	}

	this(char[] name, int ver = 3, bool raw = false) {
		File f = new File(name, FileMode.OutNew);
		this(f, ver, raw);
	}
}

/*int main(char[][] args) {
	CheckCompression(new File("dcomplib.d", FileMode.In), 3, true);
	return 0;
}*/
