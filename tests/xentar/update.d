import std.stdio, std.string, std.stream, std.file, std.path, std.c.stdlib;

//debug = DEBUG_HEADER;
//version = DUMP_BLOCKS;
//version = DEBUG_TEXT;

align(1) struct HEADER {
	ubyte[4] magic;
	ushort count;
	ushort ptr_info;
	ushort ptr_text_ptr;
	ushort ptr_text;
	uint   size;
}

struct GAMETEXT {
	static char[] decode(char[] s) {
		char[] r = s.dup;
		for (int n = 0, l = r.length; n < l; n++) r[n] = (~r[n]) + 0x20;
		return r;
	}

	static char[] encode(char[] s) {
		char[] r = s.dup;
		for (int n = 0, l = r.length; n < l; n++) r[n] = ~(r[n] -  0x20);
		return r;
	}
	
	static char[] translate_t(char[] s, TRANSLATE[] tt) {
		char[] r;
		int pos = 0;
		while (true) {
			bool found = false;
			foreach (t; tt) {
				if ((pos + t.from.length <= s.length) && s[pos..pos + t.from.length] == t.from) {
					found = true;
					r ~= t.to;
					pos += t.from.length;
					break;
				}
			}
			if (pos >= s.length) break;
			if (!found) r ~= s[pos++];
		}
		return r;
	}

	struct TRANSLATE { char[] from, to; }

	static TRANSLATE[] translate_n, translate_r;
	
	static char[] trans_n(char[] s) { return translate_t(s, translate_n); }
	static char[] trans_r(char[] s) { return translate_t(s, translate_r); }
	
	static this() {
		writefln("Preparando tabla de traducción...");
		auto s = new File("translate.tbl");
		while (!s.eof) {
			auto l = s.readLine();
			auto chunks = split(l, "=");
			if (chunks.length < 2) continue;
			if (chunks[1] == "\\n") chunks[1] = "\n";
			translate_n ~= TRANSLATE(chunks[0], chunks[1]);
			translate_r ~= TRANSLATE(chunks[1], chunks[0]);
		}
	}
}

class GAMEBLOCK {
	int id;
	ushort[] values;
	char[][] texts;
	int[] refs;
	int[int] pos_ref;
	
	this(int id, Stream s) {
		this.id = id;
		read(s);
	}
	
	void write(Stream sw) {
		auto s = new SliceStream(sw, sw.position);
		if (!values.length) return;
		HEADER h;

		// UPDATE
		for (int n = 0; n < texts.length; n++) texts[n] = texts[refs[n]];
		
		assert(values.length == texts.length);

		h.magic[0..4]  = cast(ubyte[4])"CX\x00\x01";
		h.count        = texts.length;
		h.ptr_info     = 0x10;
		h.ptr_text_ptr = h.ptr_info + 2 * (h.count + 1);
		h.ptr_text     = h.ptr_text_ptr + 2 * (h.count + 1);
		h.size         = h.ptr_text; foreach (text; texts) h.size += text.length;
		s.writeExact(&h, h.sizeof);
		
		assert(h.ptr_info == s.position);
		
		foreach (value; values) s.write(value); s.write(cast(ushort)0);
		ushort pos = h.ptr_text; s.write(pos); foreach (text; texts) { pos += text.length; s.write(cast(ushort)pos); }
		foreach (text; texts) s.writeString(GAMETEXT.encode(text));
		
		sw.position = sw.position + s.position;
	}
	
	void read(Stream s) {
		if (!s.size) return;
		version (DUMP_BLOCKS) auto so = new File(format("blocks/%03d.txt", this.id), FileMode.OutNew);
		HEADER h; s.readExact(&h, h.sizeof);
		assert(h.magic == cast(ubyte[])"CX\x00\x01");
		assert(h.size == s.size);
		auto info = new SliceStream(s, h.ptr_info, h.ptr_text_ptr);
		auto ptxt = new SliceStream(s, h.ptr_text_ptr, h.ptr_text);
		
		for (int n = 0; n < h.count; n++) {
			ushort v;
			info.read(v);
			values ~= v;
		}
		
		refs = null;
		pos_ref = null;

		for (int n = 0; n < h.count; n++) {
			ushort current; ptxt.read(current);
			char[] ss;
			
			if ((current in pos_ref) is null) pos_ref[current] = texts.length;
			
			s.position = current;
			ubyte b = 0xFF;
			while (!s.eof) {
				ubyte c;
				s.read(c);
				ss ~= c;
				if (c == 0 && b == 0) break;
				b = c;
			}
			if (id == 136) {
				//printf("%d", pos_ref[current]); if (pos_ref[current] != texts.length) printf(", %d!! - '%s'", texts.length, toStringz(texts[pos_ref[current]])); printf("\n");
				//pos_ref[current] = texts.length;
			}
			
			refs ~= pos_ref[current];
			texts ~= GAMETEXT.decode(ss);
		
			version (DUMP_BLOCKS) {
				so.writeString(GAMETEXT.decode(ss));
				so.writefln();
			}
			
			//printf("%03d: %s\n", id, toStringz());
		}
		
		version (DUMP_BLOCKS) so.close();
		
		//if (id == 136) { foreach (zref; refs) writefln(zref); exit(0); }
	}
}

class GAMESCRIPT {
	GAMEBLOCK[] blocks;
	
	this(Stream s) {
		read(s);
	}
	
	void write(Stream s) {
		ubyte[0x300] temp;
		auto s2 = new SliceStream(s, 0); s2.write(temp);
		foreach (block; blocks) {
			s.write(cast(uint)s2.position);
			block.write(s2);
		}
		s.write(s2.position);
	}
	
	void read(Stream s) {
		blocks.length = 0;
		s.position = 0;
		uint back, current;
		s.read(back);
		while (back != 0) {
			s.read(current);
			if (current < back) break;
			blocks ~= new GAMEBLOCK(blocks.length, new SliceStream(s, back, current));
			back = current;
		}
	}
}

void main() {
	writefln("Cargando KXTXE.VOL.BAK...");
	auto g = new GAMESCRIPT(new MemoryStream(cast(ubyte[])read("KXTXE.VOL.BAK")));
	
	writefln("Cargando TEXTO.TXT...");
	char[][int][int] texto_txt;

	auto s = new MemoryStream(cast(ubyte[])read("TEXTO.TXT"));
	
	if (true) {
		int bloque = -1, frase = -1;
		
		while (!s.eof) {
			auto line = s.readLine();
			if (line.length >= 0x07) {
				if (line[0..7] == "#BLOQUE") {
					bloque = std.string.atoi(strip(line[7..line.length]));
					frase = -1;
					continue;
				} else  if (line[0..6] == "#FRASE") {
					frase = std.string.atoi(strip(line[6..line.length]));
					continue;
				}
			}
			if (bloque == -1 || frase == -1) continue;
			texto_txt[bloque][frase] = strip(texto_txt[bloque][frase] ~ "\n" ~ line);
			//writefln("%d, %d", bloque, frase);
		}
	}

	writefln("Modificando textos...");
	foreach (bloque; texto_txt.keys.sort) {
		int bloque2 = bloque;
		
		while (g.blocks[bloque2].texts.length == 0) { bloque2++; assert(bloque2 < 0x300); }
		
		version (DEBUG_TEXT) {
			writefln("-----------");
			writefln("--BLOCK:%d", bloque);
			writefln("-----------");
		}
		
		foreach (frase; texto_txt[bloque].keys.sort) {
			char[] ns = GAMETEXT.trans_r(strip(texto_txt[bloque][frase])) ~ "\x1F\x1F";
			version (DEBUG_TEXT) {
				printf("O:%s\n", toStringz(g.blocks[bloque2].texts[frase]));
				printf("T:%s\n", toStringz(ns));
			}
			if (ns.length > 2) g.blocks[bloque2].texts[frase] = ns;
		}
	}
	
	writefln("Generando nuevo KXTXE.VOL...");
	g.write(new File("KXTXE.VOL", FileMode.OutNew));
	//copy("KXTXE.VOL.BAK", "KXTXE.VOL");
}