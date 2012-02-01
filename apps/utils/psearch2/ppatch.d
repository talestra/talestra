/*
	this file should compile using D compiler 1.0: http://www.digitalmars.com/d/1.0/
	tested with DMD v1.022
	License: You can use this program as you like, but you won't make me responsible for anything. *NO WARRATINES* of any kind.
*/

import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib, std.regexp, std.string, std.c.stdlib;

const char[] _VERSION_ = "2.1.1-beta";

char[][] split2(char[] s, char[] r, int count = 0) {
	char[][] rr = std.string.split(s, r);
	if (count > 0 && rr.length > count) {
		for (int n = count; n < rr.length; n++) rr[count - 1] ~= r ~ rr[n];
		rr.length = count;
	}
	return rr;
}

uint getdhvalue(char[] s) {
	uint r = 0, d, l = s.length;
	for (int n = 0; n < l; n++) {
		char c = s[n];
		if (c >= '0' && c <= '9') d = c - '0';
		else if (c >= 'a' && c <= 'f') d = c - 'a' + 0x0a;
		else if (c >= 'A' && c <= 'F') d = c - 'A' + 0x0a;
		else { d = 0; throw(new Exception("Invalid hex digit (" ~ c ~ ") in '" ~ s ~ "'")); }
		r |= d; r <<= 4;
	} r >>= 4;

	return r;
}

char[] stripcslashes(char[] s) {
	int n, p; char[] r; r.length = s.length;	
	for (n = 0, p = 0; n < s.length; n++) {
		char c = s[n];
		if (c == '\\') {
			switch (c = s[++n]) {
				case '\\': c = '\\'; break;
				case '\'': c = '\''; break;
				case '0' : c = '\0'; break;
				case 'a' : c = '\a'; break;
				case 'b' : c = '\b'; break;
				case 'n' : c = '\n'; break;
				case 'r' : c = '\r'; break;
				case 't' : c = '\t'; break;
				case 'v' : c = '\v'; break;
				case 'x' :
					c = getdhvalue(s[n + 1..n + 3]);
					n += 2;
				break;
				default:
					throw(new Exception("Invalid escape character"));
				break;
			}			
		}
		r[p++] = c;
	}
	r.length = p;
	return r;
}

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

		//r ~= translate[s[n]];
		r ~= s[n];
	}

	r ~= "\0";

	version (padding2) { while (r.length % 4 != 0) r ~= "\0"; }
	version (padding4) { while (r.length % 4 != 0) r ~= "\0"; }

	return r;
}

class RangeList {
	int padding = 1;
	int[int] rangeStart;
	int[int] rangeEnd;

	int getLastPosition() {
		int last = 0;
		foreach (int r, int l; rangeStart) if (r + l > last) last = r + l;
		return last;
	}

	void show() {
		//rangeEnd = rangeStart.rehash;
		foreach (int r, int l; rangeStart) writefln("RANGE: %08X-%08X(%d)", r, r + l, l);
	}

	uint showSummary() {
		uint c = 0; foreach (int r, int l; rangeStart) c += l;
		writefln(format("%s {", this.toString));
		writefln("  RANGE SPACE: %d", c);
		writefln("}");
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
		foreach (key; rangeStart.keys.sort) { if (rangeStart[key] >= length) return key; }
		throw(new Exception(format("Not enough space (%d)", length)));
	}

	int getAndUse(int length) {
		int r;
		use(r = getFreeRange(length), length);
		return r;
	}

	int length() {
		int r = 0; foreach (int l; rangeStart) r += l; return r;
	}
}

void patchMIPSLoadAdress(ref int lui, ref int add, int naddr) {
	lui &= 0b01111111111111110000000000000000;
	lui |= (naddr >> 16) & 0xFFFF;
		
	add &= 0b11111111111111110000000000000000;
	add |= (naddr >> 0) & 0xFFFF;
	
	add &= 0b00000011111111111111111111111111;
	add |= 0b00110100000000000000000000000000;
}

void mipsPatch(Stream fi, InputStream fp) {
	bool doPointers = true;
	
	enum PatchType {
		FIXED,
		POINTER,
		CODE,		
	}
	
	struct Patch {
		PatchType type;
		int p1, p2;
	}
	
	struct PatchText {
		int fixedPtr = 0;
		Patch[] patches;
	}
	
	PatchText[char[]] ptl;
	
	PatchText* getPatchText(char[] text) {
		if ((text in ptl) is null) ptl[text] = PatchText();
		return &ptl[text];
	}
	
	Patch* addNewPatch(char[] text, int fixed = -1) {
		PatchText* pt = getPatchText(text);
		pt.patches.length = pt.patches.length + 1;
		Patch *p = &pt.patches[pt.patches.length - 1];
		if (fixed != -1) pt.fixedPtr = fixed;
		return p;
	}
	
	int base = 0;
	RangeList rl = new RangeList;
	
	int mem2file(int mem) {
		assert(base <= mem);
		return mem - base;
	}
	
	void prepareText(PatchText* pt, char[] rtext) {
		// Debemos encontrar un sitio para el nuevo texto
		if (pt.fixedPtr != 0) return;
		pt.fixedPtr = rl.getAndUse(rtext.length);		
		
		// Escribimos texto
		fi.position = mem2file(pt.fixedPtr);
		fi.write(cast(ubyte[])rtext);
	}
	
	while (!fp.eof) {
		char[] l = std.string.stripl(fp.readLine());
		if (!l.length || l[0] == '#') continue;
			
		switch (l[0]) {
			case 'B': // Base
				char[][] list = split2(l, ":", 2);
				base = getdhvalue(list[1]);
			break;
			case 'R': // Range
				char[][] list = std.string.split(std.string.split(l, ":")[1], "-");
				int[] ptrs = [getdhvalue(list[0]), getdhvalue(list[1])];
				rl.add(ptrs[0], ptrs[1] - ptrs[0]);
			break;
			case 'F': // Fixed				
				char[][] list = split2(l, ":", 4);
				int pos = getdhvalue(list[1]), len = getdhvalue(list[2]);
				char[] text = list[3];
				{
					Patch *p = addNewPatch(text, pos);
					p.type = PatchType.FIXED;
					p.p1 = pos;
					p.p2 = len;
				}
			break;
			case 'T': // TextPointer
				char[][] list = split2(l, ":", 3);
				int pos = getdhvalue(list[1]);
				char[] text = list[2];
				{
					Patch *p = addNewPatch(text);
					p.type = PatchType.POINTER;
					p.p1 = pos;
				}
			break;
			case 'C': // Code
				char[][] list = split2(l, ":", 4);
				int pos1 = getdhvalue(list[1]), pos2 = getdhvalue(list[2]);
				char[] text = list[3];
				{
					Patch *p = addNewPatch(text);
					p.type = PatchType.CODE;
					p.p1 = pos1;
					p.p2 = pos2;
				}				
			break;
		}
	}
	
	//rl.show();
	
	foreach (char[] text, PatchText pt; ptl) {
		char[] rtext = stripcslashes(text);
		foreach (Patch p; pt.patches) {
			switch (p.type) {
				case PatchType.FIXED:
					int pos = p.p1, len = p.p2;
					if (rtext.length > len) throw(new Exception(std.string.format("Too much space in '%s'", rtext)));
					fi.position = mem2file(pos);
					fi.write(cast(ubyte[])rtext);
				break;
				case PatchType.POINTER:
					if (doPointers) {
						int ptr = p.p1;
						
						prepareText(&pt, rtext);						
						
						// Escribimos puntero
						fi.position = mem2file(ptr);
						fi.write(cast(uint)(pt.fixedPtr));
					}
				break;
				case PatchType.CODE:
					if (doPointers) {
						int i1 = p.p1, i2 = p.p2;
						int start = pt.fixedPtr;
						
						int c1, c2;
	
						prepareText(&pt, rtext);
						
						fi.position = mem2file(i1); fi.read(c1);
						fi.position = mem2file(i2); fi.read(c2);
						
						patchMIPSLoadAdress(c1, c2, pt.fixedPtr);
	
						fi.position = mem2file(i1); fi.write(c1);
						fi.position = mem2file(i2); fi.write(c2);
					}
				break;
			}
		}
	}	
}

void shownotice() {
	writefln(
		"Pointer patcher utility for MIPS - version %s\n"
		"Copyright (C) 2007 soywiz - http://www.tales-tra.com/\n"
	, _VERSION_);
}

void showusage() {
	shownotice();
	
	writef(
		"Usage: ppatch <binary> <patchfile>\n"
		"\n"
		"Examples: \n"
		"  ppatch SLUS_213.86 SLUS_213.86.patch\n"
	);
	
	exit(-1);
}

int main(char[][] args) {
	if (args.length < 3) showusage();
		
	copy(args[1], args[1] ~ ".bak");

	File f = new File(args[1], FileMode.In | FileMode.Out);
	mipsPatch(f, new File(args[2], FileMode.In));
	f.close();
	
	return 0;
}
