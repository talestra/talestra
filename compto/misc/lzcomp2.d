import std.stdio, std.string, std.file, std.stream, std.intrinsic;

int[][1 << 16] hashes;

final static ushort hash(ubyte* c) {
	return (c[0] << 0) ^ (c[1] << 4) ^ (c[2] << 8);
}

void decode(ubyte[] iv, ubyte[] ov) {
	int ip = 0, il = iv.length;
	int op = 0, ol = ov.length;
	int dist, len;
	
	void decodepos() {
		ubyte c;
		len = 0;
		dist = 0;
		
		retry:

		c = iv[ip++];
		dist = (dist << 3) | ((c >> 0) & 0b111);
		len  = (len  << 3) | ((c >> 3) & 0b111);

		switch (c >> 6) {
			// Finish.
			case 0b00:
				return;
			break;
			// More dist. d:5,l:2
			case 0b01:
				do {
					c = iv[ip++];
					dist = (dist << 5) | ((c >> 0) & 0b11111);
					len  = (len  << 2) | ((c >> 5) & 0b11);
				} while (c & 0x80);
			break;
			// More len. d:2,l:5
			case 0b10:
				do {
					c = iv[ip++];
					dist = (dist << 2) | ((c >> 0) & 0b11);
					len  = (len  << 5) | ((c >> 2) & 0b11111);
				} while (c & 0x80);
			break;
			// Mixed. d:3,l:3. next.
			case 0b11:
				dist = (dist << 3) | ((c >> 0) & 0b111);
				len  = (len  << 3) | ((c >> 3) & 0b111);
				goto retry;
			return;
		}
	}
	while (ip >= il) {
		decodepos();
		// Uncompress.
		if (dist == 0) {
			while (len-- > 0) ov[op++] = iv[ip++];
		}
		// Compress.
		else {
			while (len-- > 0) ov[op++] = ov[op - dist];
		}
	}
}

void encode() {
}

static int encodepos_simple(int dis, int len, Stream sout = null) {
	int wast = 0;
	do {
		ubyte c;
		c |= ((dis & 0b111) << 0); dis >>= 3;
		c |= ((len & 0b111) << 3); len >>= 3;
		if (dis || len) c |= 0xC0;
		if (sout !is null) sout.write(c);
		wast++;
	} while (dis || len);
	return wast;
}
static int encodepos_opt(Stream sout, int dis, int len) {
	int log2_dis = bsr(dis);
	int log2_len = bsr(len);
	// ...
	return 0;
}
alias encodepos_simple encodepos;

void main() {
	//auto data = cast(ubyte[])read("lzcomp2.d");
	//auto data = cast(ubyte[])read("gnac-ardilla.psd");
	auto data = cast(ubyte[])read("A002_12.WSC");
	//auto data = cast(ubyte[])read("out.u");
	auto sout = new File("A002_12.WSC.c9", FileMode.OutNew);
	ushort chash = hash(data.ptr);
	int uncomp_len = 0;
	int comp_size = 0;
	int wpos;
	
	int calc_wast(int dist, int len) {
		int wast = 0;
		for (int nn = 0; nn <= 7; nn++) {
			if (len  > (1 << (4 << nn))) wast++;
			if (dist > (1 << (3 << nn))) wast++;
		}
		return wast;
	}

	void flush_uncomp() {
		if (uncomp_len <= 0) return;
		//writefln("uncomp:%d", uncomp_len);
		encodepos(0, uncomp_len, sout);
		sout.write(data[wpos - uncomp_len..wpos]);
	}
	
	for (wpos = 0; wpos < data.length - 3;) {
		int maxlen = data.length - wpos;
		
		int skip = 1;
		int max_gain = 0, max_dist = 0, max_len = 0, max_wast;
		//int max_check = 16;
		int max_check = 0x10000;
		//int max_check = 0xFFFFFFFF;
		
		foreach_reverse (rpos; hashes[chash]) {
			int dist = wpos - rpos, len = 0;
			for (int n = 0; n < maxlen; n++, len++) if (data[wpos + n] != data[rpos + n]) break;
			int gain = len;
			int wast = encodepos(dist, len);
			gain -= wast;

			if (gain > max_gain) {
				max_gain = gain;
				max_dist = dist;
				max_len  = len;
				max_wast = wast;
			}
			if (max_check-- <= 0) break;
		}
		if (max_gain > 3) {
			flush_uncomp();
			skip = max_gain;
			writefln("dist:%d,len:%d,wast:%d", max_dist, max_len, max_wast);
			//writefln("comp:%d", max_len);
			encodepos(max_dist, max_len, sout);
			uncomp_len = 0;
		} else {
			uncomp_len++;
		}
		
		while (skip-- > 0) {
			hashes[chash] ~= wpos;
			chash = hash(data.ptr + wpos);
			wpos++;
		}
	}
	flush_uncomp();
	//for (int n = 0; n < (1 << 16); n++) writefln(hashes[n].length);
}