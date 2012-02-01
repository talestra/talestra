module simple_image.simple_image_png;

import simple_image.simple_image;
import std.zlib;
import crc32;

// SPECS: http://www.libpng.org/pub/png/spec/iso/index-object.html
class ImageFileFormat_PNG : ImageFileFormat {
	void[] header = x"89504E470D0A1A0A";

	override char[] identifier() { return "png"; }

	align(1) struct PNG_IHDR {
		uint width;
		uint height;
		ubyte bps;
		ubyte ctype;
		ubyte comp;
		ubyte filter;
		ubyte interlace;
	}

	override bool write(Image i, Stream s) {
		PNG_IHDR h;

		void writeChunk(char[4] type, void[] data = []) {
			uint crc = void;

			s.write(bswap(cast(uint)(cast(ubyte[])data).length));
			s.write(cast(ubyte[])type);
			s.write(cast(ubyte[])data);

			/*
			if (false) {
				//crc = init_crc32;
				crc = 0;
				foreach (c; cast(ubyte[])type) crc = update_crc32(c, crc);
				foreach (c; cast(ubyte[])data) crc = update_crc32(c, crc);
			} else if (false) {
				crc = etc.c.zlib.crc32_combine(
					etc.c.zlib.crc32(0, cast(ubyte *)type.ptr, type.length),
					etc.c.zlib.crc32(0, cast(ubyte *)data.ptr, data.length),
					data.length
				);
			} else {
			*/
				ubyte[] full = cast(ubyte[])type ~ cast(ubyte[])data;
				crc = etc.c.zlib.crc32(0, cast(ubyte *)full.ptr, full.length);
				//crc = 0;
			//}

			s.write(bswap(crc));
		}

		void writeIHDR() { writeChunk("IHDR", (cast(ubyte *)&h)[0..h.sizeof]); }
		void writeIEND() { writeChunk("IEND", []); }

		void writeIDAT() {
			ubyte[] data;

			data.length = i.height + i.width * i.height * 4;

			int n = 0;
			ubyte *datap = data.ptr;
			for (int y = 0; y < i.height; y++) {
				*datap = 0x00; datap++;
				for (int x = 0; x < i.width; x++) {
					if (i.hasPalette) {
						*datap = cast(ubyte)i.get(x, y); datap++;
					} else {
						RGBA cc = i.getColor(x, y);
						*datap = cc.r; datap++;
						*datap = cc.g; datap++;
						*datap = cc.b; datap++;
						*datap = cc.a; datap++;
					}
				}
			}

			writeChunk("IDAT", std.zlib.compress(data, 9));
		}

		void writePLTE() {
			ubyte[] data;
			data.length = i.ncolor * 3;
			ubyte* pdata = data.ptr;
			for (int n = 0; n < i.ncolor; n++) {
				RGBA c = i.color(n);
				*pdata = c.r; pdata++;
				*pdata = c.g; pdata++;
				*pdata = c.b; pdata++;
			}
			writeChunk("PLTE", data);
		}

		void writetRNS() {
			ubyte[] data;
			data.length = i.ncolor;
			ubyte* pdata = data.ptr;
			bool hasTrans = false;
			for (int n = 0; n < i.ncolor; n++) {
				RGBA c = i.color(n);
				*pdata = c.a; pdata++;
				if (c.a != 0xFF) hasTrans = true;
			}
			if (hasTrans) writeChunk("tRNS", data);
		}

		s.write(cast(ubyte[])header);
		h.width = bswap(i.width);
		h.height = bswap(i.height);
		h.bps = 8;
		h.ctype = (i.hasPalette) ? 3 : 6;
		h.comp = 0;
		h.filter = 0;
		h.interlace = 0;

		writeIHDR();
		if (i.hasPalette) writePLTE();
		writetRNS();
		writeIDAT();
		writeIEND();

		return true;
	}

	override Image read(Stream s) {
		PNG_IHDR h;

		uint Bpp;
		Image i;
		ubyte[] buffer;
		uint size, crc;
		ubyte[4] type;
		bool finished = false;

		if (!check(s)) throw(new Exception("Not a PNG file"));

		while (!finished && !s.eof) {
			s.read(size); size = bswap(size);
			s.read(type);
			uint pos = s.position;

			//writefln("%s", cast(char[])type);

			switch (cast(char[])type) {
				case "IHDR":
					s.read((cast(ubyte *)&h)[0..h.sizeof]);
					h.width = bswap(h.width); h.height = bswap(h.height);

					switch (h.ctype) {
						case 4: case 0: throw(new Exception("Grayscale images not supported yet"));
						case 2: Bpp = 3; break; // RGB
						case 3: Bpp = 1; break; // Index
						case 6: Bpp = 4; break; // RGBA
						default: throw(new Exception("Invalid image type"));
					}

					i = (Bpp == 1) ? cast(Image)(new Bitmap8(h.width, h.height)) : cast(Image)(new Bitmap32(h.width, h.height));
				break;
				case "PLTE":
					if (size % 3 != 0) throw(new Exception("Invalid Palette"));
					i.ncolor = size / 3;
					for (int n = 0; n < i.ncolor; n++) {
						RGBA c;
						s.read(c.r);
						s.read(c.g);
						s.read(c.b);
						c.a = 0xFF;
						i.color(n, c);
					}
				break;
				case "tRNS":
					if (Bpp == 1) {
						if (size != i.ncolor) throw(new Exception(std.string.format("Invalid Transparent Data (%d != %d)", size, i.ncolor)));
						for (int n = 0; n < i.ncolor; n++) {
							RGBA c = i.color(n);
							s.read(c.a);
							i.color(n, c);
						}
					} else {
						throw(new Exception(std.string.format("Invalid Transparent Data (%d != %d) 32bits", size, i.ncolor)));
					}
				break;
				case "IDAT":
					ubyte[] temp; temp.length = size;
					s.read(temp); buffer ~= temp;
				break;
				case "IEND":
					ubyte[] idata = cast(ubyte[])std.zlib.uncompress(buffer);
					ubyte *pdata = void;

					ubyte[] row, prow;

					prow.length = Bpp * (h.width + 1);
					row.length = prow.length;

					ubyte PaethPredictor(int a, int b, int c) {
						int babs(int a) { return (a < 0) ? -a : a; }
						int p = a + b - c; int pa = babs(p - a), pb = babs(p - b), pc = babs(p - c);
						if (pa <= pb && pa <= pc) return a; else if (pb <= pc) return b; else return c;
					}

					for (int y = 0; y < h.height; y++) {
						int x;

						pdata = idata.ptr + (1 + Bpp * h.width) * y;
						ubyte filter = *pdata; pdata++;

						switch (filter) {
							default: throw(new Exception(std.string.format("Row filter 0x%02d unsupported", filter)));
							case 0: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata; break; // Unfiltered
							case 1: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + row[x - Bpp]; break; // Sub
							case 2: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + prow[x]; break; // Up
							case 3: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + (row[x - Bpp], prow[x]) >> 1; break; // Average
							case 4: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + PaethPredictor(row[x - Bpp], prow[x], prow[x - Bpp]); break; // Paeth
						}

						prow[0..row.length] = row[0..row.length];

						ubyte *rowp = row.ptr + Bpp;
						for (x = 0; x < h.width; x++) {
							if (Bpp == 1) {
								i.set(x, y, *rowp++);
							} else {
								RGBA c;
								c.r = *rowp++;
								c.g = *rowp++;
								c.b = *rowp++;
								c.a = (Bpp == 4) ? *rowp++ : 0xFF;
								i.set(x, y, c.v);
							}
						}
					}
					//writefln("%d", pdata - idata.ptr);
					//writefln("%d", idata.length);
					finished = true;
				break;
				default: break;
			}
			s.position = pos + size;
			s.read(crc);
			//break;
		}

		return i;
	}

	override bool check(Stream s) {
		ubyte[] cheader; cheader.length = header.length;
		s.read(cast(ubyte[])cheader);
		return (cheader == header);
	}
}

static this() {
	ImageFileFormatProvider.registerFormat(new ImageFileFormat_PNG);
}