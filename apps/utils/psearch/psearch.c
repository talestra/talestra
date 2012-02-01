#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define uint unsigned int

#define __VERSION__ "0.9"

#define DATALEN 0x8000
uint data[DATALEN];

uint rl[32] = { 0 };
uint lui[32] = { 0 };

int ptradd = 0;

#define BUFFER_MAXLENGTH 0x100
int bufferlength = 0;
char buffer[BUFFER_MAXLENGTH];

void printrange(int cpos) {
	printf("R:%08X-%08X\n", cpos, cpos + bufferlength);
}

void psearch(FILE *f, uint *ptr, int length, int offset, int v) {
	int n;	
	
	for (n = 0; n < length; n++) {
		//int show = 0;
		int update = 0;
		int cop, rs, rt;
		short imm;
		uint cv = ptr[n];
		int cpos = offset + (n << 2) + ptradd;
		
		if (cv == v) {
			printrange(v);
			printf("T:%08X:%s\n", cpos, buffer);
		}
			
		cop = (cv >> 26);
		rs  = (cv >> 21) & 0xF;
		rt  = (cv >> 16) & 0xF;
		imm = (cv & 0xFFFF);		
		
		//if (file2mem(cpos) == 0x002CE714) show = 1;
		//if (file2mem(cpos) == 0x002CE720) show = 1;
		
		switch (cop) {
			case 0b001111: // LUI
				rl[rt] = (imm << 16);
				lui[rt] = cpos;
				update = 1;
				//if (show) printf("LUI $%d, %04X\n", rt, imm);
			break;
			case 0b001000: case 0b001001: // ADDI/ADDIU
				rl[rt] = rl[rs] + imm;
				update = 1;
				//if (show) printf("ADDI $%d, $%d, %04X\n", rs, rt, imm);
			break;
			case 0b001101: // ORI
				rl[rt] = rl[rs] | imm;
				update = 1;
				//if (show) printf("ORI $%d, $%d, %04X\n", rs, rt, imm);
			break;
			default:
			break;
		}
		
		//if (show) printf("$%d=%08X\n", rt, rl[rt]);
				
		if (update) {
			rl[0] = 0;			
			if (rl[rt] == v) {
				printrange(v);
				printf("C:%08X:%08X:%s\n", lui[rt], cpos, buffer);
			}
		}
	}
}

void psearchfile(char *name, int v) {	
	int offset = 0;
	int pos, len;
	FILE *f = fopen(name, "rb");
	if (!f) { fprintf(stderr, "No se pudo abrir el fichero"); exit(-1); }
		
	fseek(f, 0, SEEK_END);
	len = ftell(f);
	
	pos = v - ptradd;
	
	if (pos >= 0 && pos <= len) {
		fseek(f, v - ptradd, SEEK_SET);
		fread(buffer, 1, BUFFER_MAXLENGTH, f);
		buffer[BUFFER_MAXLENGTH - 1] = 0;
		bufferlength = strlen(buffer) + 1;
	}
	
		
	fseek(f, 0, SEEK_SET);
	
	while (!feof(f)) {
		int length;
		length = fread(data, 4, DATALEN, f);
		psearch(f, data, length, offset, v);
		offset += (length << 2);
	}
	
	fclose(f);
}

int dhex(char v) {
	     if (v >= '0' && v <= '9') return v - '0';
	else if (v >= 'a' && v <= 'f') return v - 'a' + 10;
	else if (v >= 'A' && v <= 'F') return v - 'A' + 10;
	else 0;
}

int shex(char *s) {
	int v = 0;
	while (*s != 0) { v <<= 4; v |= dhex(*s); s++; }
	return v;
}

void shownotice() {
	printf(
		"Pointer searcher utility for MIPS - version %s\n"
		"Copyright (C) 2007 soywiz - http://www.tales-tra.com/\n"
		"\n"
	,__VERSION__);
}

void showusage() {
	shownotice();
	
	printf(
		"Usage: psearch <file> [offset] <hexvalue>\n"
		"\n"
		"Examples: \n"
		"  psearch SLUS_213.86 FFF00 0057BFF0\n"
		"  psearch OV_PDVD_BTL_US.OVL 64B880 006C5900\n"		
	);
	exit(-1);
}

int main(int argc, char **argv) {			
	//test(); exit(0);
	
	if (argc < 3) showusage();
		
	switch (argc) {
		case 3:
			psearchfile(argv[1], shex(argv[2]));
		break;
		case 4:
			ptradd = shex(argv[2]);
			psearchfile(argv[1], shex(argv[3]));
		break;
	}	
	
	return 0;
}