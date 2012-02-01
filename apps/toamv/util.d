module util;

import std.string, std.stream, std.math, std.stdio, std.path, std.file;

//version = dump_stream;

struct V2D {
	union {
		struct { float x, y; }
		float[2] v;
	}
	char[] toString() { return std.string.format("V2D(%f,%f)", x, y); }
	float length() { return std.math.sqrt(x*x + y*y); }
}

struct V3D  {
	union {
		struct { float x, y, z; }
		float[3] v;
	}
	char[] toString() { return std.string.format("V3D(%f,%f,%f)", x, y, z); }
	float length() { return std.math.sqrt(x*x + y*y + z*z); }
}

struct FACE { ushort a, b, c; int ab, bc, ca; V3D[3] vn; V3D fn; }

debug = DebugStreamBlockTree;

class StreamBlock {
	uint type;
	uint len;
	uint sync;
	uint level;
	Stream s;
	StreamBlock p;
	StreamBlock[] childs;
	int childN;
	
	Stream sbase;
	int spos;
	
	char[] name() {
		if (!p) return std.string.format("%04d", type);
		if (!p.p) return std.string.format("%04d(%d)", type, childN);
		return p.name ~ "_" ~ std.string.format("%04d(%d)", type, childN);
	}
	
	bool eof() {
		return s.eof;
	}
	
	void writeTo(char[] file) {
		auto f = new File(file, FileMode.OutNew);
		try {
			f.copyFrom(s);
		} catch (Exception e) {
			writefln("cutted");
		}
		f.close();
	}
	
	void pad() { for (int n = 0; n < level; n++) printf("  "); }
	
	void unprocess() {
		writefln("||UNPROCESS(0x%04X)!!", type);
		version (dump_stream) {
			try { mkdir("dump"); } catch { }
			auto sw = new File(std.string.format("dump/%s", name), FileMode.OutNew);
			sw.copyFrom(s);
			sw.close();
		}
	}
	
	void unknown() {
		writefln("##UNKNOWN(0x%04X)!!", type);
	}
}

class StreamBlockEND : Exception {
	this() {
		super("StreamBlockEND");
	}
}

StreamBlock readStreamBlock(StreamBlock sb, uint sync) {
	StreamBlock r = new StreamBlock();
	
	Stream s = sb.s;
	
	try {
		s.read(r.type);
		s.read(r.len);
		s.read(r.sync);
	} catch {
		throw(new StreamBlockEND);
	}
	
	r.level = sb.level + 1;
	r.sbase = sb.sbase;
	r.spos = sb.spos + s.position;
	r.p = sb;
	if (sb) {
		r.childN = sb.childs.length;
		sb.childs ~= r;
	}
		
	if (r.sync != sync) {
		r.pad(); writefln("%08X != %08X", r.sync, sync);
		throw(new StreamBlockEND);
	}
	
	if (r.len > s.size - s.position) {
		r.pad(); writefln("warning! 0x%X > 0x%X", r.len, s.size - s.position);
		r.s = new SliceStream(r.sbase, r.spos, r.spos + r.len);
	} else {
		r.s = new SliceStream(s, s.position, s.position + r.len);
	}
	
	s.position = s.position + r.len;
	
	debug(DebugStreamBlockTree) { r.pad(); writefln("%04X: 0x%X", r.type, r.len); }
	
	return r;
}