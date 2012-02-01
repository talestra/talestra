import std.stdio, std.string, std.file, std.c.stdlib, std.stream, std.process, std.regexp, std.conv;

import elf, common;

const int defaultAlign = 1;

char[] base_boot = "..\\..\\..\\BOOT.BIN";
char[] ipsexe = "..\\..\\ips.exe";
char[] pspisodirfile = "pspisodir.txt";
char[] bindatapath = "..\\..\\..\\BIN/SRC/";
//char[] bindatapath = ".";

bool inlinepatch = false;

void updateISOEXE() {
	char[] isodir = strip(cast(char[])read(pspisodirfile));
	FILE *iso = fopen(toStringz(isodir), "r+b");

	if (!iso) {
		throw(new Exception("No se pudo abrir la ISO de PSP (" ~ pspisodirfile ~ " -> '" ~ isodir ~ "')"));
	}

	writefln("Abriendo iso en PSP (" ~ pspisodirfile ~ " -> '" ~ isodir ~ "')");

	char[] exedata = cast(char[])read("BOOT.BIN");

	char[4] elfheader;
	uint exepos;

	//iso.position = 0x00013800;
	//iso.read(cast(ubyte[])elfheader);
	exepos = 0x00013800;

	fseek(iso, exepos, SEEK_SET);
	fread(elfheader.ptr, 1, 4, iso);
	if (elfheader == "\x7fELF") {
		fseek(iso, exepos, SEEK_SET);
		writefln("EXE localizado: %d", fwrite(exedata.ptr, 1, exedata.length, iso));
	} else {
		writefln("EXE NO localizado");
	}

	exepos = 0x0038C800;

	fseek(iso, exepos, SEEK_SET);
	fread(elfheader.ptr, 4, 1, iso);
	if (elfheader == "\x7fELF") {
		fseek(iso, exepos, SEEK_SET);
		writefln("EXE localizado: %d", fwrite(exedata.ptr, 1, exedata.length, iso));
	} else {
		writefln("EXE NO localizado");
	}

	//iso.close();
	fclose(iso);
}

int main() {
	try {
	struct Fix {
		u32 pos;
		u8 size;
		u32 value;
	}

	struct Rewrite {
		ubyte type; // 0-32 1-16
		u32 i1, i2;
		u32 addr;
		u32 add;
		u8 sec;
	}

	Fix[] fixlist;
	char[] file;
	char* pt;
	int dwBase = 0x4000;
	char *strptr = null;
	struct __hirelt {
		u32  addr;
		u8   ori;
		u32 *inst;
		u32  instaddr;
	} __hirelt regs[32];
	ElfReloc[] erl;
	ElfHeader h;
	ElfProgramHeader[] ep;
	ElfSectionHeader[] es;
	char[][uint] strlist;
	uint[][char[]][2] strassoc;
	Rewrite[uint] rewrite;
	RangeList rll[2];
	rll[0] = new RangeList;
	rll[1] = new RangeList;
	File ftr;
	uint[uint] matched;
	uint[char[]] stralign;

	uint[uint] programheaders;

	void rl_show() {
		writefln();

		rll[0].showSummary();
		rll[1].showSummary();

		writefln();
	}

	void addString(uint v, char[] cstring, int calign = -1) {
		uint pheader = programheaders[v];
		strassoc[pheader][strlist[v] = cstring] ~= v;
		if (calign != -1) stralign[cstring] = calign;
		//printf("%d", programheaders[v]);
	}

	void getPatch() {
		char[][] fnames;

		bool error = false;
		bool commenting = false;

		foreach (char[] fname; listdir("translated")) {
			fname = "translated\\" ~ fname;
			if (!isfile(fname)) continue;
			ftr = new File(fname, FileMode.In);
			while (!ftr.eof) {
				bool fix = false;
				int fixlen;
				int calign = defaultAlign;
				char[] line = ftr.readLine().strip(); if (!line.length) continue;

				if (line == "/*") {
					commenting = true;
				} else if (line == "*/") {
					commenting = false;
				}

				if (commenting) continue;

				if (line[0] == '#') continue;
				if (line.length >= 2 && line[0] == '/' && line[1] == '/') continue;

				// ALIGN
				{
					auto reg = new RegExp("^A([0-9]+)", "i");
					char[][] lines = reg.match(line);
					if (lines.length) calign = toInt(lines[1]) / 8;
				}

				// FIX
				{
					auto reg = new RegExp("^FIX([0-9]+)", "i");
					char[][] lines = reg.match(line);

					if (lines.length) {
						fixlen = toInt(lines[1]);
						fix = true;
					}

				}

				int p = std.regexp.find(line, "[0-9a-fA-F]{6,6}:", "i");
				if (p == -1) continue;
				uint v = getdhvalue(line[p..p+6]);

				if (fix) {
					char[] value = line[p+7..line.length].strip();
					uint valued;
					if (value[0..2] == "0x") {
						valued = getdhvalue(value[2..value.length]);
					} else {
						valued = toInt(value);
					}

					Fix fixv;
					with (fixv) {
						pos = v;
						value = valued;
						size = fixlen;
					}

					fixlist ~= fixv;

					continue;
				}


				int cp = std.string.find(line, '\'');
				if (cp == -1) {
					printf("FORMAT ERROR: %s\n", toStringz(line));
					error = true; continue;
					//exit(-1);
				}
				if (cp+1 >= line.length) {
					printf("FORMAT ERROR: %s\n", toStringz(line));
					error = true; continue;
					//exit(-1);
				}
				char[] string = line[cp+1..line.length-1];

				addString(v, uncodestring(string), calign);
			}
			ftr.close();
			delete ftr;
		}

		if (error) exit(-1);
	}

	// Cargamos el fichero en memoria
	//copy("../../../BOOT.BIN", "BOOT.BIN");
	copy(base_boot, "BOOT.BIN");

	file = cast(char[])read("BOOT.BIN");

	// Carga el ElfHeader
	h = *cast(ElfHeader *)file;

	if (h.magic != 0x464C457F) throw(new Exception("No es un fichero ELF válido"));

	// Carga los ElfProgramHeader
	ep = new ElfProgramHeader[h.phnum];
	pt = &file[0] + h.phoff;
	for (int n = 0; n < h.phnum; n++) { ep[n] = *cast(ElfProgramHeader *)pt; pt += h.phentsize; }

	// Carga los ElfSectionHeader
	es = new ElfSectionHeader[h.shnum];
	pt = &file[0] + h.shoff;
	for (int n = 0; n < h.shnum; n++) {
		es[n] = *cast(ElfSectionHeader *)pt;
		if (n == h.shstrndx) {
			strptr = cast(char *)(&file[0] + es[n].offset);
		}
		pt += h.shentsize;
	}

	// Se recorre las secciones buscando secciones de relocs
	for (int n = 0; n < h.shnum; n++) {
		if (es[n].type != 0x700000A0) continue;
		int count = es[n].size / es[n].entsize;
		pt = cast(char *)(&file[0] + es[n].offset);
		for (int m = 0; m < count; m++) {
			erl ~= *cast(ElfReloc *)pt;
			pt += es[n].entsize;
		}
	}

	// Comprueba que hay relocs en la lista
	if (erl.length <= 0) {
		writefln("No se han encontrado relocs");
		exit(-1);
	}

	// Ordena los relocs para que las instrucciones HI y LO correspondan
	qsort(&erl[0], erl.length, ElfReloc.sizeof, &__elfreloccompare);

	foreach (ElfReloc er; erl) {
		//uint *cpt;
		//int offset = er.offset + ep[er.offph].vaddr;
		//int base   = dwBase    + ep[er.valph].vaddr;
		//int ibase   = ep[er.valph].offset;
		int ioffset = er.offset + ep[er.offph].offset;

		//cpt = cast(uint *)(&file[0] + ioffset);

		programheaders[ioffset] = er.valph;
	}

	// Obtiene los parches
	getPatch();

	FILE *fwarning = fopen("patch.warnings.txt", "wb");

	foreach (int n, ElfReloc er; erl) {
		uint *cpt;
		int offset = er.offset + ep[er.offph].vaddr;
		int base   = dwBase    + ep[er.valph].vaddr;
		int ibase   = ep[er.valph].offset;
		int ioffset = er.offset + ep[er.offph].offset;

		cpt = cast(uint *)(&file[0] + ioffset);

		switch (er.type) {
			// Los RELOC MIPS_HI16 son instrucciones LUI
			case ElfReloc.Type.MIPS_HI16:
				uint inst = *cpt;

				if ((inst >> 26) != 0xF) {
					writefln("Instrucción desconocida (se esperaba LUI)");
					break;
				}

				uint reg = (inst >> 16) & 0x1F;

				regs[reg].addr = 0;
				regs[reg].inst = cpt;
				regs[reg].ori  = 0;
				regs[reg].instaddr = ioffset;
			break;
			// Los RELOC MIPS_LO16 son instruciones con un IMM de 16 bits
			case ElfReloc.Type.MIPS_LO16:
				uint reg, hiinst, loinst = *cpt;
				reg = (loinst >> 21) & 0x1F;

				if (regs[reg].inst == null) {
					writefln("Invalid lo relocation, no matching hi 0x%08X", offset);
					break;
				}

				/*if (ioffset == 0x033D94) {
					printf("TEST BASE: %08X\n", ibase);
					exit(-1);
				}*/

				hiinst = *regs[reg].inst;
				uint addr = ((hiinst & 0xFFFF) << 16) + base;

				// ori
				if ((loinst >> 26) == 0xD) {
					addr = addr | (loinst & 0xFFFF);
					regs[reg].ori = 1;
				} else {
					addr = cast(s32)addr + cast(s16)(loinst & 0xFFFF);
				}

				uint pos = addr - base + ibase;

				if ((pos < file.length) && ((pos % 4) == 0)) {
					if (ioffset in strlist) {
						matched[pos] = ioffset;
						rll[er.valph].add(pos, getasciilen(cast(char *)(pos + &file[0])));
						{
							Rewrite rw;
							rw.type = 1;
							rw.i1 = ioffset;
							rw.i2 = cast(uint)regs[reg].inst - cast(uint)&file[0];

							rw.add = ibase;

							rw.addr = pos;
							rw.sec = er.valph;
							rewrite[ioffset] = rw;
						}
					} else if (isascii2(&file[pos])) { // No tenemos puntero WARNING
						fprintf(fwarning, "MLO:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
					}
				}

				regs[reg].addr = addr;
			break;
			// Los RELOC MIPS_32 suelen ser punteros de vectores
			case ElfReloc.Type.MIPS_32:
				uint pos = *cpt + ibase;

				if ((pos < file.length) && ((pos % 4) == 0)) {
					if (ioffset in strlist) {
						matched[pos] = ioffset;
						rll[er.valph].add(pos, getasciilen(cast(char *)(pos + &file[0])));

						{
							Rewrite rw;
							rw.type = 0;
							rw.i1 = ioffset;
							rw.i2 = 0;
							rw.addr = pos;

							rw.add = ibase;

							rw.sec = er.valph;
							rewrite[ioffset] = rw;
						}
					} else if (isascii2(&file[pos])) { // No tenemos puntero WARNING
						fprintf(fwarning, "M32:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
					}
				}
			break;
			default: break;
		}
	} // fin foreach

	//exit(-1);

	foreach (int n, ElfReloc er; erl) {
		uint *cpt;
		int offset = er.offset + ep[er.offph].vaddr;
		int base   = dwBase    + ep[er.valph].vaddr;
		int ibase   = ep[er.valph].offset;
		int ioffset = er.offset + ep[er.offph].offset;

		cpt = cast(uint *)(&file[0] + ioffset);

		switch (er.type) {
			// Los RELOC MIPS_HI16 son instrucciones LUI
			case ElfReloc.Type.MIPS_HI16:
				uint inst = *cpt;

				if ((inst >> 26) != 0xF) {
					writefln("Instrucción desconocida (se esperaba LUI)");
					break;
				}

				uint reg = (inst >> 16) & 0x1F;
				regs[reg].addr = 0;
				regs[reg].inst = cpt;
				regs[reg].ori  = 0;
				regs[reg].instaddr = ioffset;
			break;
			// Los RELOC MIPS_LO16 son instruciones con un IMM de 16 bits
			case ElfReloc.Type.MIPS_LO16:
				uint reg, hiinst, loinst = *cpt;
				reg = (loinst >> 21) & 0x1F;

				hiinst = *regs[reg].inst;
				uint addr = ((hiinst & 0xFFFF) << 16) + base;

				// ori
				if ((loinst >> 26) == 0xD) {
					addr = addr | (loinst & 0xFFFF);
					regs[reg].ori = 1;
				} else {
					addr = cast(s32)addr + cast(s16)(loinst & 0xFFFF);
				}

				uint pos = addr - base + ibase;

				if ((pos < file.length) && ((pos % 4) == 0)) {
					if (!(ioffset in strlist) && (pos in matched)) {
						printf("WARNING: NM: M32:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
						{
							Rewrite rw;
							rw.type = 1;
							rw.i1 = ioffset;
							rw.i2 = cast(uint)regs[reg].inst - cast(uint)&file[0];

							rw.add = ibase;

							rw.addr = pos;
							rw.sec = er.valph;
							rewrite[ioffset] = rw;
						}
						/*addString(uint v, char[] string) {

						}*/

						addString(ioffset, strlist[matched[pos]]);

						//strlist[ioffset] = strlist[matched[pos]];
						//strassoc[strlist[ioffset]] ~= ioffset;
					}
				}

				regs[reg].addr = addr;
			break;
			// Los RELOC MIPS_32 suelen ser punteros de vectores
			case ElfReloc.Type.MIPS_32:
				uint pos = *cpt + ibase;

				if ((pos < file.length) && ((pos % 4) == 0)) {
					if (!(ioffset in strlist) && (pos in matched)) {
						printf("WARNING: NM: M32:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
						{
							Rewrite rw;
							rw.type = 0;
							rw.i1 = ioffset;
							rw.i2 = 0;
							rw.addr = pos;
							rw.add = ibase;
							rw.sec = er.valph;
							rewrite[ioffset] = rw;
						}
						//strlist[ioffset] = strlist[matched[pos]];
						//strassoc[strlist[ioffset]] ~= ioffset;

						addString(ioffset, strlist[matched[pos]]);
					}
				}
			break;
			default: break;
		}
	} // fin foreach

	fclose(fwarning);

	rl_show();

	{
		// Creamos una copia limpia
		copy(base_boot, "BOOT.BIN");

		File f = new File("BOOT.BIN", FileMode.In | FileMode.Out);

		writefln("Escribiendo fuente de script");
		{ // FONT SCRIPT
			f.position = 0x001BD798;
			char[] data = cast(char[])read(bindatapath ~ "/FONT_MELNIC.DAT");
			f.writeExact(data.ptr, data.length);
		}

		writefln("Escribiendo fuente de menu");
		{ // FONT MENU
			f.position = 0x001B5250;
			char[] data = cast(char[])read(bindatapath ~ "/PSP-FONT.BIN");
			f.writeExact(data.ptr, data.length);
		}

		writefln("Escribiendo splash");
		{ // PRODUCED BY NAMCO - SPLASH
			f.position = 0x0017BB40;
			if (!exists("..\\..\\comptoe.exe")) {
				system("comptoe.exe -d " ~ bindatapath ~ "/SPLASH-PSP.BIN SPLASH-PSP.BIN.U > NUL");
			} else {
				system("..\\..\\comptoe.exe -d " ~ bindatapath ~ "/SPLASH-PSP.BIN SPLASH-PSP.BIN.U > NUL");
			}
			char[] data = cast(char[])read("SPLASH-PSP.BIN.U");
			f.writeExact(data.ptr, data.length);
			unlink("SPLASH-PSP.BIN.U");
		}

		writefln("Escribiendo awitdh");
		{ // Anchos de tamaño de ascii
			f.position = 0x001BD570;
			char[] data = cast(char[])read(bindatapath ~ "/AWIDTH.BIN");
			f.writeExact(data.ptr, data.length);
		}

		char zeroes[40]; for (int n = 0; n < 40; n++) zeroes[n] = 0;

		writefln("Arreglando datos");

		foreach (fix; fixlist) {
			//writefln("%08X\n%08X\n%08X\n", fix.pos, fix.size, fix.value);
			f.position = fix.pos;
			switch (fix.size) {
				case 1: f.write(cast(u8)fix.value); break;
				case 2: f.write(cast(u16)fix.value); break;
				case 4: f.write(cast(u32)fix.value); break;
				default: writefln("WARNING: No se puede fixear un tamaño de %d bytes", fix.size); break;
			}
		}

		//exit(-1);

		/*
		struct Fix {
			u32 pos;
			u8 size;
			u32 value;
		}
		*/

		//rl.getAndUse(1);

		uint usec = 0;

		for (int cph = 0; cph <= 1; cph++) {
			RangeList rl = rll[cph];
			foreach (char[] key; strassoc[cph].keys) {
				uint[] pointers = strassoc[cph][key];
				uint calign = stralign[key];

				//printf("%d,", calign);
				if (pointers.length == 0) continue;

				//printf("%s\n", key.ptr);

				//printf("Modificaciones: %d\n", strassoc[key].length);

				int dlen = key.length + (calign - 1);

				uint pos = rl.getFreeRange(dlen);
				uint rpos = pos;

				dlen = key.length;

				while (pos % calign != 0) {
					dlen++;
					pos++;
				}

				if (key == "Gran Craymel \0") {
					printf("Modificaciones: %08X\n", pos);
				}

				f.position = rpos;
				f.writeExact(&zeroes[0], pos - rpos);

				//if (calign == 4) printf("%d, %d\n", pos, pos % 4);

				//printf("%d,", pos - rpos);

				rl.use(rpos, dlen);

				//uint pos = rl.getAndUse(key.length);

				f.position = pos;
				f.writeExact(&key[0], key.length);

				foreach (uint p; pointers) {
					if (!(p in rewrite)) {
						throw(new Exception("No se sabe dónde reescribir"));
						continue;
					}

					Rewrite r = rewrite[p];

					//printf("%08X: %d: %d, %d (%d) -> %s\n", p, r.type, r.i1, r.i2, cast(int)(pos - r.addr), toStringz(key));

					switch (r.type) {
						case 0:
							uint addr;
							f.position = r.i1; f.read(addr);

							addr = pos - r.add;

							f.position = r.i1; f.write(cast(u32)addr);
						break;
						case 1: {
							uint i1 = *cast(int *)&file[r.i1];
							uint i2 = *cast(int *)&file[r.i2];
							uint addr = pos - r.add;

							/*if (((i1 >> 26) != 0xD) && (addr & 0x8000)) {

							} else {
								printf("LOL: '%s'\n", &file[0] + r.addr);
							}*/

							encodeHiLo(i2, i1, addr);

							if (decodeHiLo(i2, i1) != addr) {
								throw(new Exception("Error Fatal. No se codificó bien la instrucción."));
							}

							f.position = r.i2;
							f.write(cast(u32)i2);

							f.position = r.i1;
							f.write(cast(u32)i1);
						} break;
					}
				}
			}
		}

		f.close();
	}

	//if (!inlinepatch) {
	printf("Creando parche IPS...");
	system(ipsexe ~ " \"" ~ base_boot ~ "\" BOOT.BIN ../../../BIN/SRC/PSP-EXE.ips");
	printf("Ok\n");
	//copy("BOOT.BIN", "../../../BIN/SRC/PSP-EXE.BIN");
	//}

	//usleep(10000);
	//system("sleep 1");

	rl_show();

	try {
		writefln(); updateISOEXE(); writefln();
	} catch (Exception e) {
		writefln(e.toString());
	}

	unlink("BOOT.BIN");

	} catch (Exception e) {
		writefln("ERROR: %s", e.toString());
	}

	if (inlinepatch) {
		system("PAUSE");
	}

	return 0;
}