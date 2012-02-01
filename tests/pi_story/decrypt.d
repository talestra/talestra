import std.file, std.string, std.stream, std.path;
import std.stdio;

ubyte[] decrypt(ubyte[] data) {
	ubyte* cur = data.ptr, end = data.ptr + data.length;
	for (;cur < end; cur++) *cur ^= 0x84;
	return data;
}

void main() {
	bool start = false;
	foreach (file; listdir("RES", "*")) {
		char[] file2 = "U" ~ file[1..file.length];
		writefln("%s", file);
		ubyte[] data; scope (exit) { delete data; data = null; }
		try {
			bool doprocess = false;
			bool dodecrypt = false;
			
			if (!std.file.exists(file2)) doprocess = true;
			//doprocess = true;
			
			switch (tolower(getExt(file))) {
				case "mnani":
				case "nani":
					doprocess = true;
			
				case "fna":
				case "fna1":
				case "tna":
				case "moani":
					writefln("       not decrypting");
				break;
				default:
					dodecrypt = true;
				break;
			}
			
			if (doprocess) {
				data = cast(ubyte[])read(file);
				if (dodecrypt) decrypt(data);
				write(file2, data);
			}
		} catch {
		}
	}
}