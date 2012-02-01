import std.stdio;
import std.file;
import std.string;
import std.stream;

/*
Images:
EDT - True (Color) - 2E545255458D5D8CCB0000010000 - Header 0x22 bytes?
ED8 - 8bit (Color) - 2E384269748D5D8CCB0000010000

Common header:

ushort width
ushort height
ushort unk1
ushort unk2
uint compressed_size

*/

void extract(char[] pak) {
	uint offset;
	auto s = new BufferedFile(pak ~ ".PAK"); scope (exit) s.close();
	char[] path; try { mkdir(path = "data/" ~ pak); } catch { }
	ushort count;
	s.read(count);
	char[][] names;
	uint[] offsets;
	for (int n = 0; n < count; n++) {
		char[] base = strip(s.readString(8));
		char[] ext  = split(strip(s.readString(4)), "\0")[0];
		char[] name = base ~ "." ~ ext;
		s.read(offset);
		offsets ~= offset;
		names ~= name;
	}
	Stream[char[]] files;
	for (int n = 0; n < count - 1; n++) {
		files[names[n]] = new SliceStream(s, offsets[n], offsets[n + 1]);
	}
	
	foreach (name; files.keys.sort) { auto stream = files[name];
		writefln("%s", name);
		auto so = new File(path ~ "/" ~ name, FileMode.OutNew);
		so.copyFrom(stream);
		so.close();
	}
}

void main() {
	extract("A98SYS");
}