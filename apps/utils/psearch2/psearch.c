#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Aliases
#define uint unsigned int

// Versión del programa
#define __VERSION__ "2.2.0-beta"

// Datos binarios
int datalength = 0;
uint *data = NULL;

// Estado de análisis; almacena los valores de los 32 registros
// y las direcciones de las instrucciones lui.
typedef struct {
	uint rld[32];
	uint lui[32];
} ANALYSIS_STATE;

#define MAX_RANGE 0x1000
typedef struct {
	int ptr;
	int len;
} RANGE;

int ranges_count = 0;
RANGE ranges[MAX_RANGE];

#define MAX_RESULT 0x1000

typedef struct {
	int v1, v2;
	char *text;
} RESULT;
int results_count = 0;
RESULT results[MAX_RESULT];

// Dirección base en la que se carga el binario en memória
int base = 0;

// Valores a buscar y listado de cantidad de resultados
int valueslength;
int* values = NULL;
int* found = NULL;

// Buffer usado para almacenar la cadena de la dirección actual
char *buffer = "";

// Muestra un rango para una dirección no mostrada
void print_range(int value) {
	int n; for (n = 0; n < valueslength; n++) {
		if (values[n] != value) continue;
		if (found[n] == 1) printf("R:%08X-%08X\n", value, value + strlen(buffer) + 1);
		return;
	}
}

// Comprueba un valor de la lista de valores, guarda en buffer el puntero al texto
int check_value(int cv) {
	int n; for (n = 0; n < valueslength; n++) {
		if (values[n] != cv) continue;
		int pos = cv - base;
		buffer = (pos >= 0 && pos <= (datalength << 2)) ? ((char *)data + pos) : "";
		found[n]++;
		return 1;
	}
	return 0;
}

void print_addcslashes(char *buffer) {
	for (;*buffer != 0;buffer++) {
		char c = *buffer;
		switch (c) {
			case '\a' : printf("\\a" ); break;
			case '\b' : printf("\\b" ); break;
			case '\n' : printf("\\n" ); break;
			case '\r' : printf("\\r" ); break;
			case '\t' : printf("\\t" ); break;
			case '\v' : printf("\\v" ); break;			
			case '\\' : printf("\\\\"); break;
			case '"'  : printf("\\\""); break;
			case '\'' : printf("\\\'"); break;
			default: printf((c < 0x20) ? "\\x%02X" : "%c", c); break;
		}
	}
}

void result_clear() {
	int n;
	for (n = 0; n < results_count; n++) free(results[n].text);
	results_count = 0;
}

int result_add(int v1, int v2) {
	int n;
	for (n = 0; n < results_count; n++) if (results[n].v1 == v1 && results[n].v2 == v2) return 0;
	
	results[results_count].v1 = v1;
	results[results_count].v2 = v2;
	results[results_count].text = malloc(strlen(buffer) + 1);
	strcpy(results[results_count].text, buffer);
	results_count++;
	
	return 1;
}

void result_print() {
	int n;
	for (n = 0; n < results_count; n++) {
		if (results[n].v2 == 0) {
			printf("T:%08X:", results[n].v1);
			print_addcslashes(results[n].text);
			printf("\n");					
		} else {
			printf("C:%08X:%08X:", results[n].v1, results[n].v2);
			print_addcslashes(results[n].text);
			printf("\n");			
		}
	}
	if (!results_count) {
		printf("No se encontraron punteros a esa/s dirección/es\n");
	}
}

// Analiza parte de los datos con un estado de análisis para búsqueda en código
void psearch(int start, int level, ANALYSIS_STATE state) {	
	int n, m;
	int branch = -1;
	
	for (n = start; n < datalength; n++) {		
		int isbranch = 0, update = 0, show = 0;
		uint cv = data[n]; // Dato actual de 32 bits
		int cpos = base + (n << 2); // Dirección actual
		int j, cop, rs, rt; // Partes de la instrucción
		short imm;
		
		// Puntero de texto
		if (check_value(cv)) {
			print_range(cv);
			result_add(cpos, 0);
		}
		
		// TIPO:I | Inmediato
		cop = (cv >> 26);
		rs  = (cv >> 21) & 0x1F;
		rt  = (cv >> 16) & 0x1F;
		imm = (cv & 0xFFFF);
		
		// TIPO:J | Salto incondicional largo
		//j   = cv & 0b11111111111111111111111111;
		
		//if (cpos >= 0x00389458 && cpos <= 0x00389488) show = 1;
		
		// Comprueba el código de operación
		switch (cop) {
			// Saltos cortos
			case 0b000100: case 0b000101: isbranch = 1; break; // BEQ, BNE
			case 0b000001: switch (rt) { case 0b00001: case 0b10001: case 0b00000: case 0b10000: isbranch = 1; } break; // BGEZ, BGEZAL, BLTZ, BLTZAL
			case 0b000111: if (rt == 0) isbranch = 1; break; // BGTZ				
			case 0b000110: if (rt == 0) isbranch = 1; break; // BLEZ
			// Saltos largos
			//case 0b000010: break; // J
			// Carga de datos típicas (LUI + ADDI/ORI)
			case 0b001111: // LUI
				state.rld[rt] = (imm << 16);
				state.lui[rt] = cpos;
				update = 1;
				if (show) printf("LUI $%d, %04X\n", rt, imm);
			break;
			case 0b001000: case 0b001001: // ADDI/ADDIU
				state.rld[rt] = state.rld[rs] + imm;
				update = 1;
				if (show) printf("ADDI $%d, $%d, %04X\n", rs, rt, imm);
			break;
			case 0b001101: // ORI
				state.rld[rt] = state.rld[rs] | imm;
				update = 1;
				if (show) printf("ORI $%d, $%d, %04X\n", rs, rt, imm);
			break;
		}
		
		if (update) {
			state.rld[0] = 0;			
			
			if (show) printf("## r%d = %08X\n", rt, state.rld[rt]);
				
			if (check_value(state.rld[rt])) {
				print_range(state.rld[rt]);
				result_add(state.lui[rt], cpos);
			}
		}
		
		if (branch != -1) {
			if (level > 0) return;
			psearch(branch, level + 1, state);
			branch = -1;
		}
		
		if (isbranch) branch = n + imm;
	}	
}

// Hace el análisis de un fichero
void psearchfile(char *name) {	
	int pos, len; FILE *f;
	ANALYSIS_STATE state = { 0 };
	
	// Trata de abrir el fichero
	if (!(f = fopen(name, "rb"))) { fprintf(stderr, "No se pudo abrir el fichero"); exit(-1); }
	
	// Obtiene el tamaño del fichero
	fseek(f, 0, SEEK_END); datalength = (len = ftell(f)) >> 2;
	
	// Lee el contenido entero del fichero y lo cierra
	fseek(f, 0, SEEK_SET);
	data = (uint *)malloc(datalength * 4);		
	fread(data, 4, datalength, f);	
	fclose(f);

	// Hace las busquedas pertinentes en el fichero	
	psearch(0, 0, state);
	
	result_print();
	
	/*{
		int n;
		for (n = 0; n < valueslength; n++) {
			if (found[n]) { n = -1; break; }
		}
		if (n != -1) printf("No se encontraron punteros a esa dirección\n");
	}*/
	
	// Libera los datos
	result_clear();
	free(data);
	data = NULL;
		
}

// Obtiene el valor de un dígito hexadecimal
int dhex(char v) { if (v >= '0' && v <= '9') return v - '0'; else if (v >= 'a' && v <= 'f') return v - 'a' + 10; else if (v >= 'A' && v <= 'F') return v - 'A' + 10; else return 0; }
	
// Obtiene el valor de una cadena hexadecimal
int shex(char *s) { int v = 0; while (*s != 0) { v <<= 4; v |= dhex(*s); s++; } return v; }

void shownotice() {
	printf(
		"Pointer searcher utility for MIPS - version %s\n"
		"Copyright (C) 2007 soywiz - http://www.tales-tra.com/\n"
		"\n"
	, __VERSION__);
}

void showusage() {
	shownotice();
	
	printf(
		"Usage: psearch <file> <offset> [<hexvalue> ...]\n"
		"\n"
		"Examples: \n"
		"  psearch SLUS_213.86 FFF00 0057BFF0\n"
		"  psearch OV_PDVD_BTL_US.OVL 64B880 006C5900 006C63C0\n"
	);
	
	exit(-1);
}

int main(int argc, char **argv) {
	int n;
	
	if (argc < 4) showusage();
	
	valueslength = argc - 3;
	values = (int *)malloc(sizeof(int) * valueslength);
	found = (int *)malloc(sizeof(int) * valueslength);
	for (n = 0; n < valueslength; n++) {
		values[n] = shex(argv[n + 3]);
		found[n] = 0;
	}
	
	base = shex(argv[2]);
	psearchfile(argv[1]);
	
	free(values); values = NULL;
	free(found ); found = NULL;
	
	return 0;
}