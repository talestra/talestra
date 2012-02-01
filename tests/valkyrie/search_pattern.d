import std.string, std.stdio, std.stream, std.file;

ubyte[] normalize(ubyte[] text) {
	int[0x100] translate = void; translate[0..0x100] = -1;
	ubyte[] text2 = new ubyte[text.length];
	int count_symbols = 0;

	for (int n = 0, len = text.length; n < len; n++) { int cn = text[n];
		int* translate_cn = &translate[cn];
		if (*translate_cn == -1) *translate_cn = count_symbols++;
		text2[n] = *translate_cn;
	}
	return text2;
}

/*bool compare_normalize(ubyte[] text, ubyte[] normalized_search) {
	int[0x100] translate; translate[0..0x100] = -1;
	ubyte[] text2 = new ubyte[text.length];
	int count_symbols = 0;

	for (int n = 0; n < text.length; n++) { int cn = text[n];
		if (translate[cn] == -1) translate[cn] = count_symbols++;
		text2[n] = translate[cn];
		if (text2[n] != normalized_search[n]) return false;
	}
	return true;
}*/

void search_pattern(ubyte[] data, ubyte[] search) {
	auto search_normalized = normalize(search);

	for (int n = 0; n <= data.length - search.length; n++) {
		if (normalize(data[n..n + search.length]) == search_normalized) {
		//if (compare_normalize(data[n..n + search.length], search_normalized)) {
			writefln("%08X find!", n);
			//writefln("  %s", data[n..n + search.length]);
			for (int m = 0; m < search.length; m++) {
				writefln("%02X: %s", data[n + m], cast(char)search[m]);
			}
		}
	}
}

void main() {
	//search_pattern(cast(ubyte[])read("dumpram.bin"), cast(ubyte[])"waiting for someone");
	search_pattern(cast(ubyte[])read("dumpram.bin"), cast(ubyte[])"you're waiting for someone");
}