import std.stream, std.file, std.stdio;
import simple_image.simple_image;
import simple_image.simple_image_png;

void uncompress24(ubyte[] src, ubyte[] dst) {
	ubyte* s = src.ptr, s_e = src.ptr + src.length;
	ubyte* d = dst.ptr, d_e = dst.ptr + dst.length;
	ushort k;
	
	while (true) {
		k = *s++ | 0x100;

		while (k != 1) {
			if (s >= s_e) break;
			if (d >= d_e) break;
			
			//writefln(k & 1);
			
			if (k & 1) {
				*d++ = *s++;
				*d++ = *s++;
				*d++ = *s++;
				//*d++ = *s++;
				*d++ = 0xFF;
			} else {
				try {
					ushort v = *cast(ushort*)s;
					uint offset = (v >> 4) * 4;
					uint count = (v & 0xF) + 1;
					uint *cfrom = cast(uint*)(d - offset);
					uint *cto = cast(uint*)d;
					d += count * 4;
					s += 2;
					//writefln("%d, %d", offset, count);
					while (count--) *cto++ = *cfrom++;
				} catch (Exception e) {
				}
			}
			
			k >>= 1;
		}
		
		if (s >= s_e) break;
		if (d >= d_e) break;
	}
}

void convert(char[] i) {
	ubyte[] dst;
	ubyte[] src;
	ubyte type;
	ushort width, height;
	uint size_c, size_u;

	char[] o = i ~ ".png";
	
	//if (std.file.exists(o)) { writefln("Already Exists"); return; }

	Stream s = new File(i);
	s.read(type);
	s.read(width);
	s.read(height);
	if (width > 2048 || height > 2048) throw(new Exception("Invalid image size"));

	switch (type) {
		default: throw(new Exception("Invalid file type"));
		case 2:
			ubyte[] d;
			ubyte count;
			s.read(count);
			if (count != 1) throw(new Exception("Invalid count"));
			d.length = 0x0a;
			s.read(d);
			
			s.position = 0x21;

			s.read(size_c);
			
			if (size_c >= 32 * 1024 * 1024) throw(new Exception("Compressed data too big"));
			
			src.length = size_c;
			s.read(size_u);

			/*
			writefln(size_c);
			writefln(size_u);
			writefln(width, ",", height);
			writefln(size_u - width * height * 4 + 8);
			*/
			
			//s.position = size_u - width * height * 4 + 8;
			
			s.position = 0x50 + 0;
			
			writefln(s.position);
			
			s.read(src);
			
			//if (width * height * 4 != size_u) throw(new Exception("Mismatch stream/image size"));

			Bitmap32 bmp = new Bitmap32(width, height);
			
			try {
				uncompress24(src, cast(ubyte[])bmp.data);
			} catch (Exception e) {
				writefln("error");
			}
			
			for (int n = 0; n < bmp.data.length; n++) bmp.data[n] = RGBA.toBGRA(bmp.data[n]);
			
			ImageFileFormatProvider["png"].write(bmp, o);			
		break;
		case 0:
			s.read(size_c);
			
			if (size_c >= 32 * 1024 * 1024) throw(new Exception("Compressed data too big"));
			
			src.length = size_c;
			s.read(size_u);

			writefln(size_c);
			writefln(size_u);
			
			s.read(src);
			
			if (width * height * 4 != size_u) throw(new Exception("Mismatch stream/image size"));

			Bitmap32 bmp = new Bitmap32(width, height);
			
			uncompress24(src, cast(ubyte[])bmp.data);
			
			for (int n = 0; n < bmp.data.length; n++) bmp.data[n] = RGBA.toBGRA(bmp.data[n]);
			
			ImageFileFormatProvider["png"].write(bmp, o);
		break;
	}
}

int main(char[][] args) {

	//convert("CG/CGCT01.g00");
	
	convert("NYED_CT03_01.g00");

	return 0;

	foreach (dir; ["BG", "CG"]) {
		foreach (n; listdir(dir)) {
			if (n.length < 4) continue;
			if (n[n.length - 4..n.length] != ".g00") continue;
			//writefln(n);
			convert(dir ~ "/" ~ n);
		}
	}
	
	return 0;
}