/*
	this file should compile using D compiler 1.0: http://www.digitalmars.com/d/1.0/
	tested with DMD v1.022
	License: You can use this program as you like, but you won't make me responsible for anything. *NO WARRATINES* of any kind.
*/

import std.stdio, std.string, std.c.stdlib, std.file, std.stream;

const char[] _VERSION_ = "3.0.0-beta";

// Prints a non utf-8 string
void writeln(char[] s) { printf("%s", std.string.toStringz(s)); }

interface Printable { void print(); }

class PatchPointer : Printable {
	int ptr, cv;	
	this(int cv, int ptr) { this.cv = cv; this.ptr = ptr; }
	void print() { printf("T:%08X:%s\n", ptr, toStringz(search[cv].text)); }
}

class PatchCode : Printable {
	int lui, add, cv;	
	this(int cv, int lui, int add) { this.cv = cv; this.lui = lui; this.add = add; }	
	void print() { printf("C:%08X:%08X:%s\n", lui, add, toStringz(search[cv].text)); }
}

struct SEARCH_INFO {
	char[] text;
	int start;
	int length;
	Printable[int] patches;
}

struct ANALYSIS_STATE {
	uint rld[32];
	uint lui[32];
}

class Memory {
	void[][int] mem;
	
	void map(int addr, void[] data) {
		mem[addr] = data;
	}
	
	void *addr(int addr) {
		foreach (start, data; mem) {
			ubyte[] cdata = cast(ubyte[])data;
			if ((addr >= start) && (addr < start + cdata.length)) return cdata.ptr + (addr - start);
		}
		return null;
	}
}

Memory memory;

SEARCH_INFO[int] search;

void psearch() {	
	foreach (addr, data; memory.mem) {
		ANALYSIS_STATE state;
		psearch(cast(int[])data, addr, 0, 0, state);
	}
}

void psearch(int[] data, int data_base, int start, int level, ANALYSIS_STATE state) {	
	int n, m;
	int branch = -1;
	
	for (n = start; n < data.length; n++) {		
		bool isbranch = false, update = false, show = false;
		
		uint cv = data[n];               // Dato actual de 32 bits
		int cpos = data_base + (n << 2); // Dirección actual
		int j, cop, rs, rt;              // Partes de la instrucción
		short imm;                       // Valor inmediato

		// Comprobamos si hemos encontrado un puntero de 32 bits		
		if (cv in search) search[cv].patches[cpos] = new PatchPointer(cv, cpos);
		
		// TIPO:I | Inmediato
		cop = (cv >> 26) & 0b111111; // 6 bits
		rs  = (cv >> 21) & 0b11111;  // 5 bits
		rt  = (cv >> 16) & 0b11111;  // 5 bits
		imm = (cv >>  0) & 0xFFFF;   // 16 bits
		
		// TIPO:J | Salto incondicional largo
		//j   = cv & 0x3FFFFFF; // 26 bits
		
		//if (cpos >= 0x00389458 && cpos <= 0x00389488) show = 1;
		
		// Comprueba el código de operación
		switch (cop) {
			// Saltos cortos
			case 0b000100: case 0b000101: isbranch = true; break; // BEQ, BNE
			case 0b000001: switch (rt) { case 0b00001: case 0b10001: case 0b00000: case 0b10000: isbranch = true; default: } break; // BGEZ, BGEZAL, BLTZ, BLTZAL
			case 0b000110: case 0b000111: if (rt == 0) isbranch = true; break; // BLEZ, BGTZ				
			// Saltos largos
			//case 0b000010: break; // J
			// Carga de datos típicas (LUI + ADDI/ORI)
			case 0b001111: // LUI
				state.rld[rt] = (imm << 16);
				state.lui[rt] = cpos;
				if (show) printf("LUI $%d, %04X\n", rt, imm);
				update = true;
			break;
			case 0b001000: case 0b001001: // ADDI/ADDIU
				state.rld[rt] = state.rld[rs] + imm;
				if (show) printf("ADDI $%d, $%d, %04X\n", rs, rt, imm);
				update = true;
			break;
			case 0b001101: // ORI
				state.rld[rt] = state.rld[rs] | imm;
				if (show) printf("ORI $%d, $%d, %04X\n", rs, rt, imm);
				update = true;
			break;
			default: break;
		}
		
		if (update) {
			state.rld[0] = 0x00000000;			
			
			if (show) printf("## r%d = %08X\n", rt, state.rld[rt]);
				
			if (state.rld[rt] in search) {
				search[state.rld[rt]].patches[cpos] = new PatchCode(state.rld[rt], state.lui[rt], cpos);
			}
		}
		
		if (branch != -1) {
			if (level > 0) return;
			psearch(data, data_base, branch, level + 1, state);
			branch = -1;
		}
		
		if (isbranch) branch = n + imm;
	}	
}

char[] addcslashes(char *buffer) {
	char[] r;
	for (;*buffer != 0;buffer++) {
		char c = *buffer;
		switch (c) {
			case '\a' : r ~= "\\a" ; break;
			case '\b' : r ~= "\\b" ; break;
			case '\n' : r ~= "\\n" ; break;
			case '\r' : r ~= "\\r" ; break;
			case '\t' : r ~= "\\t" ; break;
			case '\v' : r ~= "\\v" ; break;			
			case '\\' : r ~= "\\\\"; break;
			case '"'  : r ~= "\\\""; break;
			case '\'' : r ~= "\\\'"; break;
			default: if (c < 0x20) r ~= std.string.format("\\x%02X", cast(int)c); else r ~= c; break;
		}
	}
	return r;
}

void psearchfile() {
	foreach (k, e; search) {
		char *ptr = cast(char *)memory.addr(k);
		if (!ptr) continue;
		search[k].text = addcslashes(ptr);
		search[k].length = search[k].text.length + 1;
	}
	
	search = search.rehash;
	
	psearch();
	
	foreach (k; search.keys.sort) {
		SEARCH_INFO si = search[k];
		if (si.patches.length) printf("R:%08X-%08X\n", si.start, si.start + si.length);
	}
	foreach (k; search.keys.sort) {
		SEARCH_INFO si = search[k];
		foreach (k2; si.patches.keys.sort) {
			si.patches[k2].print();
		}
	}
	
	/*
	Printable[int] patches;
	
	foreach (k; search.keys.sort) {
		SEARCH_INFO si = search[k];
		if (si.patches.length) printf("R:%08X-%08X\n", si.start, si.start + si.length);
		foreach (k2, p; si.patches) patches[k2] = p;
	}
	
	foreach (k; patches.keys.sort) {
		Printable p = patches[k];
		p.print();
	}	
	*/
}

void shownotice() {
	writeln(
		"Pointer searcher utility for MIPS - version " ~ _VERSION_ ~ "\n"
		"Copyright (C) 2007 soywiz - http://www.tales-tra.com/\n"
	);
}

void showusage() {
	shownotice();
	
	writeln(
		"Usage: psearch [<switches> ...] [<hexvalues> ...]\n"
		"\n"
		"<switches>\n"
		"  -m <map>\n"
		"  -mf <mapfile>\n"
		"\n"
		"<map>: \n"
		"  a map is a string <file>[:range][:loading address]\n"
		"\n"
		"  examples:\n"
		"    OV_PDVD_BTL_US.OVL:64B880\n"
		"      will load entire OV_PDVD_BTL_US.OVL at adress 64B880\n"
		"    OV_PDVD_BTL_US.OVL:0-100:64B880\n"
		"      will load first 256 bytes of OV_PDVD_BTL_US.OVL at adress 64B880\n"
		"\n"
		"<mapfile>: \n"
		"  mapfile is a file with several maps in separated lines\n"
		"\n"
		"Examples: \n"
		"  psearch -mf map 0057BFF0\n"
		"  psearch -m OV_PDVD_BTL_US.OVL:64B880 006C5900 006C63C0\n"
		"  psearch -m OV_PDVD_BTL_US.OVL:0-100:64B880 006C5900 006C63C0\n"
	);
	
	exit(-1);
}

int hexdec(char v) {
	if (v >= '0' && v <= '9') return v - '0' +  0;
	if (v >= 'A' && v <= 'F') return v - 'A' + 10;
	if (v >= 'a' && v <= 'f') return v - 'a' + 10;
	throw(new Exception("Not an hex digit: " ~ v));
}

int hexdec(char[] v) {
	int r;
	try { 		
		foreach (c; v) { r <<= 4; r |= hexdec(c); }
	} catch (Exception e) {
		throw(new Exception("Not an hex value: " ~ v));
	}
	return r;
}

void map_file(char[] info) {
	char[][] ainfo = std.string.split(info, ":");
	if (ainfo.length == 0) return;
	char[] sname = ainfo[0], saddr, srange;
	if (ainfo.length > 2) srange = ainfo[1];
	if (ainfo.length > 1) saddr = ainfo[ainfo.length - 1];
	int addr = hexdec(saddr);
	
	if (srange.length) {
		char[][] arange = std.string.split(srange, "-");
		int start = hexdec(arange[0]), end = hexdec(arange[1]);
		memory.map(addr, (cast(ubyte[])std.file.read(sname))[start..end]);
	} else {
		memory.map(addr, std.file.read(sname));
	}
}

int main(char[][] args) {
	char[][] params = args[1 .. args.length];
	char[][] maps;
	memory = new Memory;
	
	for (int n = 0; n < params.length; n++) {				
		char[] cp = params[n];
		
		void require_nparams(int m) {
			if (n + m >= params.length) throw(new Exception(std.string.format("Switch '%s' requires %d parameters", cp, m)));
		}
		
		switch (cp[0]) {
			case '-':
				switch (cp[1..cp.length]) {
					case "mf":
						require_nparams(1);
						File f = new File(params[n + 1]);
						while (!f.eof) {
							char[] line = std.string.strip(f.readLine());
							if (!line.length) continue;
							maps ~= line;							
						}
						f.close();
						n += 1;
					break;
					case "m":
						require_nparams(1);
						maps ~= params[n + 1];						
						n += 2;
					break;
					default:
						writefln("Unknown switch '" ~ cp ~ "'");
					break;
				}
			break;
			default:
				SEARCH_INFO si;
				si.start = hexdec(cp);
				search[si.start] = si;
			break;
		}
	}
	
	if (!search.length || !maps.length) showusage();
		
	foreach (map; maps) map_file(map);
	
	/*
	data_base = hexdec(args[2]);
	
	foreach (v; args[3 .. args.length]) {
		SEARCH_INFO si;
		si.start = hexdec(v);
		search[si.start] = si;
	}
		
	*/

	psearchfile();
		
	return 0;
}