import std.stream;
import std.stdio;
import std.intrinsic;
import std.path;
import std.file;
import std.process;

//debug = gim_stream;

align(1) struct TGA_Header {
   char  idlength;
   char  colourmaptype;
   char  datatypecode;
   short colourmaporigin;
   short colourmaplength;
   char  colourmapdepth;
   short x_origin;
   short y_origin;
   short width;
   short height;
   char  bitsperpixel;
   char  imagedescriptor;
}

align(1) struct RGBA {
	union {
		struct {
			ubyte r;
			ubyte g;
			ubyte b;
			ubyte a;
		}
		struct {
			ubyte[4] vv;
		}
		uint v;
	}
}

void saveTGA(Image i, Stream s) {
	TGA_Header h;

	uint toColor(uint c) {
		RGBA ic; ic.v = c;
		RGBA oc;

		oc.vv[0] = ic.vv[2];
		oc.vv[1] = ic.vv[1];
		oc.vv[2] = ic.vv[0];
		oc.vv[3] = ic.vv[3];

		//writefln("R:%02X, G:%02X, B:%02X, A:%02X", ic.r, ic.g, ic.b, ic.r);

		return oc.v;
	}

	int bpp = i.bpp;
	bool tcolor = (bpp != 8);

	if (bpp == 8) {
		h.idlength = 0;
		h.colourmaptype = 1;
		h.datatypecode = 1;
		h.colourmaporigin = 0;
		h.colourmaplength = i.ncols();
		h.colourmapdepth = 32;
		h.x_origin = 0;
		h.y_origin = 0;
		h.width = i.width;
		h.height = i.height;
		h.bitsperpixel = 8;
	} else {
		h.idlength = 0;
		h.colourmaptype = 0;
		h.datatypecode = 2;
		h.colourmaporigin = 0;
		h.colourmaplength = 0;
		h.colourmapdepth = 0;
		h.x_origin = 0;
		h.y_origin = 0;
		h.width = i.width;
		h.height = i.height;
		h.bitsperpixel = 32;
	}
	h.imagedescriptor = 0b00_1_0_1000;

	s.writeExact(&h, h.sizeof);

	// CLUT
	if (h.colourmaptype) {
		for (int n = 0; n < h.colourmaplength; n++) {
			//writefln("%08X", i.getcol(n));
			s.write(toColor(i.getcol(n)));
		}
	}

	ubyte[] data;
	data.length = h.width * h.height * (tcolor ? 4 : 1);
	writef("(%dx%d)", h.width, h.height);

	ubyte *ptr = data.ptr;
	for (int y = 0; y < h.height; y++) {
		for (int x = 0; x < h.width; x++) {
			if (tcolor) {
				*cast(uint *)ptr = cast(uint)toColor(i.get(x, y));
				ptr += 4;
			} else {
				*ptr = cast(ubyte)i.get(x, y);
				ptr++;
			}
		}
	}

	s.write(data);
}

abstract class Image {
	ubyte bpp();
	int ncols();
	uint getcol(int idx);
	int width();
	int height();
	void set(int x, int y, uint v);
	uint get(int x, int y);
}

align(1) struct GIM_IHeader {
	uint _u1;

	ushort type;
	ushort _u2;

	ushort width;
	ushort height;

	ushort bpp;

	ushort xbs;
	ushort ybs;

	ushort[0x17] _u5;
}

uint c16_565_32(ushort c) {
	RGBA cc;
	const int[] s = [5, 6, 5, 0];
	const int[] mask = [(1 << s[0]) - 1, (1 << s[1]) - 1, (1 << s[2]) - 1, (1 << s[3]) - 1];
	const int[] disp = [0, s[0], s[0] + s[1], s[0] + s[1] + s[2]];

	if (false) {
		cc.r = (((c >> disp[0]) & mask[0]) * 255) >> (s[0]);
		cc.g = (((c >> disp[1]) & mask[1]) * 255) >> (s[1]);
		cc.b = (((c >> disp[2]) & mask[2]) * 255) >> (s[2]);
		cc.a = (((c >> disp[3]) & mask[3]) * 255) >> (s[3]);
	} else {
		cc.r = (((c >> disp[0]) & mask[0]) * 255) >> (s[0]);
		cc.g = (((c >> disp[1]) & mask[1]) * 255) >> (s[1]);
		cc.b = (((c >> disp[2]) & mask[2]) * 255) >> (s[2]);
		cc.a = 0xFF;
	}

	return cc.v;
}

alias c16_565_32 c16_32;

class GIM_Image : Image {
	GIM_IHeader header;
	GIM_Image clut;
	uint[] data;

	ubyte bpp() { return header.bpp; }
	int width() { return header.width; }
	int height() { return header.height; }
	int ncols() {
		if (clut is null) return (1 << header.bpp);
		return clut.header.width * clut.header.height;
	}
	uint getcol(int idx) {
		if (clut is null) {
			RGBA c; c.r = c.g = c.b = c.a = (idx * 255) / (1 << header.bpp);
			return *cast(uint *)&c;
		}
		return clut.get(idx, 0);
	}

	void readHeader(Stream s) {
		s.readExact(&header, header.sizeof);
		data = new uint[header.width * header.height];
	}

	bool check(int x, int y) {
		return (x >= 0 && y >= 0 && x < header.width && y < header.height);
	}

	void set(int x, int y, uint v) {
		if (!check(x, y)) return;
		data[y * header.width + x] = v;
	}

	uint get(int x, int y) {
		if (!check(x, y)) return 0;
		return data[y * header.width + x];
	}

	void setBlock(int sx, int sy, void[] data) {
		//writefln("%d, %d", sx, sy);
		switch (header.bpp) {
			case 32: {
				uint[] d4 = cast(uint[])data;
				for (int y = 0, n = 0; y < header.ybs; y++) for (int x = 0; x < header.xbs; x++, n++) {
					set(sx + x, sy + y, d4[n]);
				}
			} break;
			case 16: {
				ushort[] d2 = cast(ushort[])data;
				for (int y = 0, n = 0; y < header.ybs; y++) for (int x = 0; x < header.xbs; x++, n++) {
					set(sx + x, sy + y, c16_32(d2[n]));
				}
			} break;
			case 8: {
				ubyte[] d1 = cast(ubyte[])data;
				for (int y = 0, n = 0; y < header.ybs; y++) for (int x = 0; x < header.xbs; x++, n++) {
					set(sx + x, sy + y, d1[n]);
				}
			} break;
			case 4: {
				ubyte[] d1 = cast(ubyte[])data;
				for (int y = 0, n = 0; y < header.ybs; y++) for (int x = 0; x < header.xbs; x += 2, n++) {
					set(sx + x + 0, sy + y, (d1[n] >> 0) & 0xF);
					set(sx + x + 1, sy + y, (d1[n] >> 4) & 0xF);
				}
			} break;
			default: {
				throw(new Exception(std.string.format("Unprocessed BPP (%d)", header.bpp)));
			} break;
		}
	}

	void dump() {
		for (int y = 0; y < header.height; y++) {
			for (int x = 0; x < header.width; x++) {
				printf("%02X", get(x, y));
			}
			printf("\n");
		}
	}
}

class GIM {
	const char[] errbase = "GM9031";

	Image[] images;

	this() {
	}

	this(Stream s) {
		open(s);
	}

	void open(Stream s) {
		char[16] hdr;
		s.readExact(hdr.ptr, hdr.length);
		if (hdr != "MIG.00.1PSP\0\0\0\0\0") throw(new Exception("Invalid GIM " ~ errbase ~ "001"));
		processStream(s);
	}

	void processStream(Stream s, int level = 0) {
		uint type, len, unk1, unk2;
		Stream cs;

		char[] pad; for (int n = 0; n < level; n++) pad ~= " ";

		GIM_Image img, clut;

		while (!s.eof) {
			int start = s.position;

			s.read(type);
			s.read(len);
			s.read(unk1);
			s.read(unk2);
			cs = new SliceStream(s, start + 0x10, len - 0x10);

			debug(gim_stream) writefln(pad ~ "type: %04X (%04X)", type, len);

			switch (type) {
				case 0x02: // GimContainer
					processStream(cs, level + 1);
				break;
				case 0x03: // Image
					processStream(cs, level + 1);
				break;
				case 0x04: // ImagePixels
				case 0x05: // ImagePalette
				{
					ubyte[] block;
					// 0x40 bytes header
					GIM_Image i = new GIM_Image;
					i.readHeader(cs);

					//writefln("POS: %08X", cs.position);

					//i.header.bpp = 8;

					debug(gim_stream) writefln(pad ~ " [%d] [%2d] (%dx%d) (%dx%d)", i.header.type, i.header.bpp, i.header.width, i.header.height, i.header.xbs, i.header.ybs);

					//i.header.xbs = (1 << (i.header.type - 1));
					switch (i.header.type) {
						case 0x00: i.header.xbs =  8; break;
						case 0x03: i.header.xbs =  4; break;
						case 0x05: i.header.xbs = 16; break;
						case 0x04: i.header.xbs = 32; break;
						default:
							throw(new Exception(std.string.format("Unknown image type (%d)", i.header.type)));
						break;
					}

					//i.header.xbs = 256 / (i.header.ybs * i.header.bpp / 8);
					//writefln(i.header.xbs);

					block.length = i.header.xbs * i.header.ybs * i.header.bpp / 8;

					//writefln(block.length);
					//return;

					for (int y = 0; y < i.header.height; y += i.header.ybs) for (int x = 0; x < i.header.width; x += i.header.xbs) {
						cs.read(block);
						i.setBlock(x, y, block);
					}

					if (type == 0x04) img = i; else clut = i;
				}
				case 0xFF: // Comments
				break;
				default:
					throw(new Exception(std.string.format("Invalid GIM " ~ errbase ~ "002 type:%04X", type)));
				break;
			}

			s.position = start + len;
		}

		if (img && clut) img.clut = clut;
		//writefln("%08X, %08X", cast(void *)img, cast(void *)clut);

		if (img) {
			images ~= img;
			//writefln(img);
			//img.dump();
		}
	}
}

void treeProcess(char[] path, bool delegate(char[] filename, char[] path, char[] bf) callback = null) {
	//writefln("[0]");
	foreach (f; listdir(path)) {
		char[] rf = path ~ "\\" ~ f;
		//writefln("[1]");
		if (isdir(rf)) {
			treeProcess(rf, callback);
		} else {
			if (callback !is null) callback(rf, path, f);
		}
		//writefln("[2]");
	}
	//writefln("[3]");
}

int main(char[][] args) {
	/*if (true) {
		char[] name;
		name = "data/mp_haruhi/Common_0/eyelash.gim";
		name = "data/5taku.gim";
		foreach (i; (new GIM(new File(name))).images) saveTGA(i, new File("demo.tga", FileMode.OutNew));
		return -1;
	}*/

	treeProcess("data", delegate bool(char[] f, char[] path, char[] bf) {
		if (f.length < 4) return true;
		if (f[f.length-4..f.length] != ".gim") return true;
		//if (bf != "map0.gim") return true;

		char[] npath = "tga." ~ path;

		writef("%s...", f);

		if (!exists(npath)) {
			try {
				system("mkdir " ~ npath ~ " 2> NUL");
				//mkdir(npath);
			} catch { }
		}

		char[] cf = std.string.format("%s\\%s.%d.tga", npath, bf, 0);

		if (!exists(cf)) {
			foreach (n, i; (new GIM(new File(f))).images) {
				saveTGA(i, new File(std.string.format("%s\\%s.%d.tga", npath, bf, n++), FileMode.OutNew));
			}
			writefln("...Ok");
		} else {
			writefln("...Exists");
		}

		return true;
	});

	return 0;
}