module txd;

import std.string, std.stream, std.stdio, std.math, std.intrinsic, std.file, std.path;
import util, opengl;

align(1) struct RGBA {
	union {
		struct { ubyte r; ubyte g; ubyte b; ubyte a; }
		ubyte[4] vv;
		uint v;
	}
	
	static RGBA opCall(ubyte r, ubyte g, ubyte b, ubyte a = 0xFF) {
		RGBA c;
		c.r = r; c.g = g; c.b = b; c.a = a;
		return c;
	}	
	
	static RGBA toBGRA(RGBA c) {
		ubyte r = c.r;
		c.r = c.b;
		c.b = r;
		return c;
	}	
}

abstract class BMP {
	abstract void set(int x, int y, uint c);
	abstract void set32(int x, int y, uint c);

	abstract uint get(int x, int y);
	abstract uint get32(int x, int y);
	void save(char[] name) { }
	abstract int w();
	abstract int h();
	void palettebmp(BMP32 pal) { palette(pal.data); }
	void palette(RGBA[] colors) { }
	bool hasPalette() { return false; }
}

class BMP32 : BMP {
	RGBA[] data;
	int width, height;
	
	this(int w, int h) { data.length = (width = w) * (height = h); }
	
	uint* pos(int x, int y) { return cast(uint *)&data[y * width + x]; }
	uint* datai() { return pos(0, 0); } 
	
	void set(int x, int y, uint c) { *pos(x, y) = c; }
	uint get(int x, int y) { return *pos(x, y); }
	uint get32(int x, int y) { return get(x, y); }
	void set32(int x, int y, uint c) { *pos(x, y) = c; }
	
	int w() { return width; }
	int h() { return height; }
	
	static BMP32 createFrom(BMP from, int w = 0, int h = 0) {
		auto r = new BMP32(w ? w : from.w, h ? h : from.h);
		for (int y = 0; y < r.height; y++) for (int x = 0; x < r.width; x++) r.set32(x, y, from.get32(x, y));
		return r;
	}
	
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

	override void save(char[] name) {
		auto s = new File(name, FileMode.OutNew);
		BMP32.write(this, s);
		s.close();
	}

	static override bool write(BMP32 i, Stream s) {
		TGA_Header h;

		h.idlength = 0;
		h.x_origin = 0;
		h.y_origin = 0;
		h.width = i.w;
		h.height = i.h;
		h.colourmaporigin = 0;
		h.imagedescriptor = 0b_00_1_0_1000;
		h.colourmaptype = 0;
		h.datatypecode = 2;
		h.colourmaplength = 0;
		h.colourmapdepth = 0;
		h.bitsperpixel = 32;

		s.writeExact(&h, h.sizeof);

		ubyte[] data;
		data.length = h.width * h.height * 4;

		ubyte *ptr = data.ptr;
		
		for (int y = 0; y < h.height; y++) for (int x = 0; x < h.width; x++) {
			RGBA c; c.v = i.get32(x, y);
			RGBA co = RGBA.toBGRA(c);
			*cast(uint *)ptr = co.v;
			ptr += 4;
		}

		s.write(data);

		return false;
	}
	
}

class BMP8 : BMP {
	RGBA[] pal;
	ubyte[] data;
	int width, height;
	
	this(int w, int h) { data.length = (width = w) * (height = h); }
	
	ubyte* pos(int x, int y) { return cast(ubyte *)&data[y * width + x]; }
	
	void set(int x, int y, uint c) { *pos(x, y) = c; }
	void set32(int x, int y, uint c) { }
	uint get(int x, int y) { return *pos(x, y); }
	uint get32(int x, int y) { return pal[get(x, y) % pal.length].v; }
	
	int w() { return width; }
	int h() { return height; }
	
	void palette(RGBA[] colors) {
		pal = colors;
	}
	
	override bool hasPalette() { return true; }
}

class Texture {
	uint GlTex;
	BMP32 bitmap;
	
	private static int NextPowerOfTwo(int v) { int c = 1; while ((c <<= 1) < v) { } return c; }
	
	void gen() { glGenTextures(1, &GlTex); }
	void bind() { glBindTexture(GL_TEXTURE_2D, GlTex); }
	
	static Texture fromBitmap(BMP bmpp) {
		Texture i = new Texture;

		i.bitmap = BMP32.createFrom(bmpp, NextPowerOfTwo(bmpp.w), NextPowerOfTwo(bmpp.h));

		i.gen();
		i.bind();

		glTexImage2D(GL_TEXTURE_2D, 0, 4, i.bitmap.w, i.bitmap.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, i.bitmap.datai);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
		//static int textid = 0; i.bitmap.save(format("%d.tga", textid)); textid++;
		
		return i;
	}
	
	void save(char[] name) {
		bitmap.save(name);
	}
}

class TXD {
	char[] tname;
	Texture[char[]] texs;
	
	int length() { return texs.length; }
	
	Texture* get(char[] name) {
		return (name in texs);
	}
	
	ubyte[] unpack4(ubyte[] s) {
		ubyte[] d; d.length = s.length * 2;
		int n = s.length;
		ubyte* dst = d.ptr, src = s.ptr;
		while (n--) {
			ubyte c = *src++;
			*dst++ = (c >> 0) & 0xF;
			*dst++ = (c >> 4) & 0xF;
		}
		return d;
	}
	
	void drawBPP(BMP8 img, ubyte[] d_in) {
		const uint table[][] = [
			[ 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C, 0x02, 0x06, 0x0A, 0x0E, 0x12, 0x16, 0x1A, 0x1E ],
			[ 0x11, 0x15, 0x19, 0x1D, 0x01, 0x05, 0x09, 0x0D, 0x13, 0x17, 0x1B, 0x1F, 0x03, 0x07, 0x0B, 0x0F ],		
			[ 0x10, 0x14, 0x18, 0x1C, 0x00, 0x04, 0x08, 0x0C, 0x12, 0x16, 0x1A, 0x1E, 0x02, 0x06, 0x0A, 0x0E ],
			[ 0x01, 0x05, 0x09, 0x0D, 0x11, 0x15, 0x19, 0x1D, 0x03, 0x07, 0x0B, 0x0F, 0x13, 0x17, 0x1B, 0x1F ],
		];
		
		void dop(int x, int y, int off, bool toggle = false) {
			//writefln("DOP (%d, %d, %d, %d)", x, y, off, toggle);
			
			int w2 = img.w * 2;
			
			for (int n = 0; n < 16; n++) {
				img.set(n + x, 0 + y, d_in[table[0 + toggle * 2][n] + off]);
				img.set(n + x, 2 + y, d_in[table[1 + toggle * 2][n] + off]);
			}
		}

		int off = 0;
		
		bool toggle = false;
		
		try {
			for (int y = 0; y < img.h; y += 4) {
				for (int x = 0; x < img.w; x += 16, off += 32) dop(x, y + 0, off, toggle);
				for (int x = 0; x < img.w; x += 16, off += 32) dop(x, y + 1, off, toggle);
				toggle = !toggle;
			}
		} catch (Exception e) { }
	}
	
	void draw4BPP(BMP8 img, ubyte[] updata) {
		ubyte[] d_in = unpack4(updata);
		drawBPP(img, d_in);
	}
	
	void draw8BPP(BMP8 img, ubyte[] data) {
		drawBPP(img, data);
	}

	void processImagePicturePixelData(Stream s, int rwidth, int rheight) {
		int idx = 0;
		int bpp;
		
		//writefln("processImagePicturePixelData");
		
		BMP32 bpal = new BMP32(16, 16);
		auto bimg = new BMP8(rwidth, rheight);
		
		while (!s.eof) {
			uint imagetype;
			uint width, height;
			ulong blocksize;
			uint unk[5];
			s.read(imagetype);
			s.read(unk[0]);
			s.read(unk[1]);
			s.read(unk[2]);
			s.read(unk[3]);
			s.read(unk[4]);
			
			bool ex;
			
			while (!s.eof) {
				ulong type;
				s.read(type);
				//writefln("POS: %08X: %016X", s.position, type);
				switch (type) {
					/*default:
						writefln("%d", type);
					break;*/
					case 0x51:
						s.read(width);
						s.read(height);
					break;
					case 0x52:
						ulong zunk;
						s.read(zunk);
					break;
					case 0x53:
						s.read(blocksize);
					break;
					case 0x00:
						int w_h = rwidth * rheight;
						ubyte[] data = cast(ubyte[])s.readString(blocksize * 0x10);
						if (idx == 0) {
							// 8bpp
							if (data.length == w_h) {
								draw8BPP(bimg, data);
								bpp = 8;
							}
							// 4bpp
							else  if (data.length * 2 == w_h) {
								draw4BPP(bimg, data);
								bpp = 4;
							}
							// ??bpp
							else {
								throw(new Exception("Unimplemented BPP for texture"));
							}
						} else {
							foreach (n, v; cast(uint[])data) {
								bpal.set(n, 0, v | 0xFF000000);
							}
						}
						ex = true;
						idx++;
					break;
				}
				if (ex) break;
			}
		}
		
		//writefln("processImagePicturePixelData(2)");
		
		if (bpp == 8) {
			for (int n = 8; n < 256; n += 4 * 8) {
				for (int m = 0; m < 8; m++) {
					uint ct = bpal.get(n + m, 0);
					bpal.set(n + m, 0, bpal.get(n + m + 8, 0));
					bpal.set(n + m + 8, 0, ct);
				}
			}
		}
		
		if (bpal) bimg.palettebmp = bpal;
		texs[tname] = Texture.fromBitmap(bimg);
		
		//delete bpal;
		//delete bimg;
		
		writefln("Loaded texture: '%s'", tname);
	}
	
	void processImagePicture(StreamBlock s) {
		int state = 0, width, height;
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02002D);
				switch (sb.type) {
					default: break;
					case 0x01: {
						switch (state) {
							case 0: {
								sb.s.read(width);
								sb.s.read(height);
								//writefln("IMAGE (%d, %d)", width, height);
								state = 1;
							} break;
							case 1:
								processImagePicturePixelData(sb.s, width, height);
								//writefln("IMAGE");
							break;
						}
					} break;					
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}		
	}
	
	void processImage(StreamBlock s) {
		int state = 0;
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02002D);
				
				switch (sb.type) {
					default: break;
					case 0x01: {
						switch (state) {
							case 0:
								uint magic;
								sb.s.read(magic);
								if (magic != 0x00325350) throw(new Exception("Not a PS2 Image"));
								state = 1;
							break;
							case 1:
								processImagePicture(sb);
							break;
						}
					} break;
					case 0x02: {
						char[] name = std.string.toString(toStringz(sb.s.readString(sb.s.size)));
						if (name.length) {
							//writefln("NAME: %s", name);
							this.tname = name;
						}
					} break;					
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}

	void process(StreamBlock s) {
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02002D);
				switch (sb.type) {
					default: break;
					case 0x15: // Image stream
						processImage(sb);
					break;
					case 0x01:
						ushort count, dummy;
						sb.s.read(count);
						sb.s.read(dummy);
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}
	
	this(StreamBlock sb) {
		process(sb);
	}
}