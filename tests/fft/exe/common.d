module common;

import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib;

//version = padding2;

class RangeList {
	int[int] rangeStart;
	int[int] rangeEnd;

	void show() {
		//rangeEnd = rangeStart.rehash;
		foreach (int r, int l; rangeStart) writefln("RANGE: %08X-%08X(%d)", r, r + l, l);
	}

	uint showSummary() {
		uint c = 0; foreach (int r, int l; rangeStart) c += l;
		writefln("RANGE SPACE: %d", c);
		return c;
	}

	void add(int from, int length) {
		/*if (from in rangeStart) {
			if (length > rangeStart[from]) {
				rangeEnd.remove(from + rangeStart[from]);
				rangeStart[from] = length;
				rangeEnd[from + length] = length;
			}
			return;
		}*/

		foreach (int afrom, int alen; rangeStart) {
			if (from >= afrom && from < afrom + alen) {
				return;
			}
		}

		//printf("ADD_RANGE: %08X, %d\n", from, length);

		if (from in rangeEnd) {
			int rstart = from - rangeEnd[from];
			rangeStart[rstart] += length;
			rangeEnd.remove(from);
			rangeEnd[from + length] = rangeStart[rstart];
		} else {
			rangeStart[from] = rangeEnd[from + length] = length;
		}

		//removeInnerRanges();

		//showRanges();
	}

	int removeInner() {
		int removed = 0;
		bool done = false;
		while (!done) {
			done = true;
			foreach (int afrom, int alen; rangeStart) {
				foreach (int bfrom, int blen; rangeStart) {
					if (afrom == bfrom) continue;

					if (bfrom < afrom + alen && bfrom + blen > afrom + alen) {
						show();

						writefln("%08X(%d)", afrom, alen);
						writefln("%08X(%d)", bfrom, blen);

						assert(1 == 0);
					}

					if (bfrom < afrom && bfrom + blen > afrom) {
						show();
						assert(1 == 0);
					}

					if (afrom >= bfrom && afrom + alen <= bfrom + blen) {
						done = false;
						rangeEnd.remove(afrom + alen);
						rangeStart.remove(afrom);
						removed++;
						break;
					}
				}

				if (!done) break;
			}
		}
		return removed;
	}

	void use(int from, int length) {
		rangeEnd[from + rangeStart[from]] -= length;
		if (rangeStart[from] - length > 0) {
			rangeStart[from + length] = rangeStart[from] - length;
		}
		rangeStart.remove(from);
	}

	int getFreeRange(int length) {
		foreach (int key, int value; rangeStart) if (value >= length) return key;
		throw(new Exception("Not enough space"));
	}

	int getAndUse(int length) {
		int r;
		use(r = getFreeRange(length), length);
		return r;
	}

	int length() {
		int r = 0; foreach (int l; rangeStart) r += l; return r;
	}

	char[] extractTextAddRange(Stream s) {
		char[] rtext;
		char[] text; char c; int len = 1;
		int from = s.position;

		//while ((c = s.getc) != '\0') {
		while ((c = s.getc) != '\xFE') {
			char[] cc = [c];
			len++;
			
			if (c in translate) cc = translate[c];
			
			rtext ~= cc;

			/*if (c == '\n') { text ~= "\\n"; continue; }
			if (c == '\r') { text ~= "\\r"; continue; }
			if (c == '<' ) { text ~= "<3C>"; continue; }
			if (c == '>' ) { text ~= "<3E>"; continue; }

			// Caracteres de control
			if (c  < 0x20) { text ~= dsprintf("<%02X>", c); continue; }
			if (c >= 0x7f) { text ~= dsprintf("<%02X>", c); continue; }

			// Caracteres multibyte
			if (c == 0x81 || c == 0x82 || c == 0x83 || c == 0x84) {
				len++; rtext ~= c;
				text ~= dsprintf("<%02X%02X>", c, s.getc);
				continue;
			}*/

			// Caracter normal
			text ~= cc;
		} rtext ~= "\0";

		// Alineacion
		while ((len % 4) != 0) {
			len++; rtext ~= "\0";
		}

		version(showtext) {
			printf("'");
			for (int n = 0; n < len; n++) {
				putchar(rtext[n]);
			}
			printf("'\n");
		}

		add(from, len);

		return text;
	}
}


char[] dsprintf(...) {
	char[] ret; void dsprintfp(dchar c) { ret ~= c; }
    std.format.doFormat(&dsprintfp, _arguments, _argptr);
    return ret;
}


uint getdhvalue(char[] s) {
	uint r = 0, d, l = s.length;
	for (int n = 0; n < l; n++) {
		char c = s[n];
		if (c >= '0' && c <= '9') d = c - '0';
		else if (c >= 'a' && c <= 'f') d = c - 'a' + 0x0a;
		else if (c >= 'A' && c <= 'F') d = c - 'A' + 0x0a;
		else { d = 0; throw(new Exception("Digito invalido (" ~ c ~ ")")); }
		r |= d; r <<= 4;
	} r >>= 4;

	return r;
}

char[][char] translate;

char[] uncodestring(char[] s) {
	char[] r;

	for (int n = 0; n < s.length; n++) {
		if (s[n] == '\\') {
			switch (s[++n]) {
				case 'n': r  ~= '\n'; break;
				case 'r': r  ~= '\r'; break;
				case 't': r  ~= '\t'; break;
				default:
					printf("FORMAT ERROR: %s\n", toStringz(s));
					exit(-1);
				break;
			}

			continue;
		}

		if (s[n] == '<') {
			char hx[2];
			n++;

			while (n < s.length && s[n] != '>') {
				r ~= cast(char)getdhvalue(s[n..n+2]);
				n += 2;
			}

			continue;
		}

		r ~= translate[s[n]];
	}

	r ~= "\0";

	version (padding2) { while (r.length % 4 != 0) r ~= "\0"; }
	version (padding4) { while (r.length % 4 != 0) r ~= "\0"; }

	return r;
}

char[] makestringz(char[] s, int l) {
	char[] r = s[0..s.length];
	while (r.length < l) r ~= '\0';
	return r[0..l];
}

static this() {
	for (int n = 0; n < 0x100; n++) translate[cast(char)n] ~= cast(char)n;

	File tf;
	try {
		tf = new File("../translate.tbl");
	} catch (Exception e) {
		tf = new File("translate.tbl");
	}
	while (!tf.eof) {
		char[] l = tf.readLine().strip();
		if (!l.length) continue;
		char[][] ls = l.split("=");
		
		if (ls.length < 2) continue;
		if (ls[0].length < 1) continue;
		
		if (ls[0].length % 2 == 0 && ls.length >= 2) {
			translate[getdhvalue(ls[0])] = ls[1];
		} else {
			translate[ls[0][0]] = ls[1];
		}
	} tf.close();
}
