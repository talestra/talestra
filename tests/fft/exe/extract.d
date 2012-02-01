import std.stdio, std.string, std.file, std.c.stdlib, std.stream;

import elf;

int main() {
	FILE* unfout, unfoutun, grfout;
	char[] file;
	char* pt;
	int dwBase = 0x4000;
	char *strptr = null;
	struct __hirelt {
		u32  addr;
		u8   ori;
		u32 *inst;
	} __hirelt regs[32];
	ElfReloc[] erl;
	ElfHeader h;
	ElfProgramHeader[] ep;
	ElfSectionHeader[] es;
	uint[][uint] href;

	// Cargamos el fichero en memoria
	copy("../BOOT.BIN", "BOOT.BIN");
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
		writefln("%08X", 0x3A8344 + es[n].name);
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

	// Abrimos los ficheros
	grfout   = fopen("original\\group.txt", "wb");
	unfout   = fopen("original\\match.txt", "wb");
	unfoutun = fopen("original\\unmatch.txt", "wb");

	foreach (int n, ElfReloc er; erl) {
		uint *cpt;
		int offset = er.offset + ep[er.offph].vaddr;
		int base   = dwBase    + ep[er.valph].vaddr;
		int ibase   = ep[er.valph].offset;
		int ioffset = er.offset + ep[er.offph].offset;

		cpt = cast(uint *)(&file[0] + ioffset);

		switch (er.type) {
			// Los RELOC MIPS_26 solo se usan para instruciones de tipo J, no nos
			// interesa para extraer textos ASCII
			case ElfReloc.Type.MIPS_26:
				uint inst = *cpt;

				uint addr = ((inst & 0x03FFFFFF) << 2); // Cargamos la dirección de la instrucción
				addr += base;                           // Añadimos la base a la instrucción
				inst &= ~0x03FFFFFF;                    // Borramos la dirección de la instrucción
				inst |= (addr >> 2) & 0x03FFFFFF;       // Añadimos la nueva dirección nuevamente a la instrucción

				*cpt = inst;
			break;
			// Los RELOC MIPS_HI16 son instrucciones LUI
			case ElfReloc.Type.MIPS_HI16:
				uint inst = *cpt;

				if ((inst >> 26) != 0xF) {
					writefln("Instrucción desconocida (se esperaba LUI)");
					break;
				}

				uint reg = (inst >> 16) & 0x1F;

				if (regs[reg].inst) {
					u32 oldinst;
					oldinst = *(regs[reg].inst);
					oldinst &= ~0xFFFF;
					if ((regs[reg].addr & 0x8000) && (!regs[reg].ori)) {
						regs[reg].addr += 0x10000;
					}
					oldinst |= (regs[reg].addr >> 16);
					*regs[reg].inst = oldinst;
				}

				regs[reg].addr = 0;
				regs[reg].inst = cpt;
				regs[reg].ori  = 0;
			break;
			// Los RELOC MIPS_LO16 son instruciones con un IMM de 16 bits
			case ElfReloc.Type.MIPS_LO16:
				uint reg, hiinst, loinst = *cpt;
				reg = (loinst >> 21) & 0x1F;

				if (regs[reg].inst == null) {
					writefln("Invalid lo relocation, no matching hi 0x%08X", offset);
					break;
				}

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
					if (isascii(&file[pos])) {
						href[pos] ~= ioffset;
						fprintf(unfout, "MLO:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
					} else {
						fprintf(unfoutun, "MLO:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
					}
				}

				loinst &= ~0xFFFF;
				loinst |= (addr & 0xFFFF);
				regs[reg].addr = addr;

				*cpt = loinst;
			break;
			// Los RELOC MIPS_32 suelen ser punteros de vectores
			case ElfReloc.Type.MIPS_32:
				uint pos = *cpt + ibase;

				if ((pos < file.length) && ((pos % 4) == 0)) {
					if (isascii(&file[pos])) {
						href[pos] ~= ioffset;
						fprintf(unfout, "M32:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
					} else {
						fprintf(unfoutun, "MLO:%06X: '%s'\n", ioffset, toStringz(getstr(cast(char *)(pos + &file[0]))));
					}
				}

				*cpt += base;
			break;
			// El resto de tipos de RELOC no los manejamos
			default:
				writefln("Unknown reloc type");
			break;
		}
	}

	foreach (k; href.keys.sort) {
		uint[] ll = href[k];
		foreach (uint k2, uint n; ll) {
			if (k2 != 0) fprintf(grfout, ",");
			fprintf(grfout, "%06X", n);
		}
		fprintf(grfout, ": '%s'\n", toStringz(getstr(cast(char *)(&file[0] + k))));
	}

	fclose(unfout);
	fclose(unfoutun);
	fclose(grfout);

	return 0;
}