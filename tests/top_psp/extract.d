import dcomplib, std.string, std.stream, std.stdio;

struct entry {
	uint type;
	uint pos;
}

int main() {
	ubyte[] data;
	entry[] entries;
	uint count;
	
	File f = new File("i_c09.d");
	f.read(count);
	entries.length = count + 1;
	
	for (int n = 0; n < count; n++) {
		f.read(entries[n].type);
		f.read(entries[n].pos);
		entries[n].pos += 4 + 8 * count;
	}
	
	f.seek(0, SeekPos.End);
	
	with (entries[count]) {
		type = 0;
		pos = f.position;
	}
	
	
	for (int n = 0; n < count; n++) {
		f.position = entries[n].pos;
		data.length = entries[n + 1].pos - f.position;
		f.read(data);
		
		writefln("%d", data.length);
		
		if (data.length == 0) continue;
		
		try {
			(new File(std.string.format("dump%03d", n), FileMode.OutNew)).copyFrom(
				new CompressedStream(new MemoryStream(data))
				//new MemoryStream(data)
			);
		} catch (Exception e) {
			writefln("ERROR: %s", e.toString);
		}
	}
	
	return 0;
}