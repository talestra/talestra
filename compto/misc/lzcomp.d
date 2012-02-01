import std.stdio, std.string, std.stream;

struct MatcherRLE
{
	public ubyte[] data;
	public int len = 0;
	private int from = 0, to = 0;
	
	void find(int pos) {
		// Invalid range.
		if (pos < 0 || pos >= data.length) {
			from = to = pos;
		} else {
			// Uncached range.
			if (pos < from || pos >= to) {
				to = from = pos;
				if (from < data.length) {
					ubyte v = data[from];
					while (++to < data.length && data[to] == v) { }
				}
			}
		}

		// Cached range.
		len = to - pos;
	}
}

struct MatcherLZ
{
	ubyte[] data;
	int offset;
	int len;
	
	int len_max = 12, dist_max = (1 << 12); // 0x1000
	
	void find(int offset_seq) {
		find(offset_seq - dist_max, offset_seq);
	}

	void find(int offset_search, int offset_seq) {
		if (offset_search < 0) offset_search = 0;

		assert(offset_search <= offset_seq);

		int clen = 0, clen_max = len_max;
		len = 0;
		if (offset_seq + clen_max >= data.length) clen_max = data.length - offset_seq - 1;
		for (int n = offset_search; n < offset_seq; n++) {
			for (clen = 0; clen <= clen_max; clen++) {
				if (data[n + clen] != data[offset_seq + clen]) break;
			}
			if (clen > len) {
				len = clen;
				offset = n;
			}
		}
	}
}

class Matcher
{
	MatcherRLE rle;
	MatcherLZ  lz;
	ubyte c;
	ubyte[] data;
	int buf_read;
	int buf_read_cached = -1;

	this(ubyte[] data, int start = 0, int lz_dist_max = (1 << 12), int lz_len_max = 12) {
		buf_read = start;
		rle.data = data;
		lz.data = data;
		lz.len_max = lz_len_max;
		lz.dist_max = lz_dist_max;
		this.data = data;
	}
	
	bool current() {
		if (buf_read >= data.length) return false;
		if (buf_read != buf_read_cached) {
			c = data[buf_read];
			rle.find(buf_read);
			lz.find(buf_read);
			buf_read_cached = buf_read;
		}
		return true;
	}
	
	void next(int count = 1) {
		buf_read += count;
	}
}

void main() {
	ubyte[] data = [0, 0, 0, 0, 1, 1, 2, 3, 3, 3, 3, 0, 1, 1, 2, 3, 3, 3];
	auto m = new Matcher(data, 0);
	while (m.current) {
		// RLE
		if (m.rle.len >= 3) {
			writefln("RLE (%02X) : %d", m.c, m.rle.len);
			m.next(m.rle.len);
		}
		// LZ
		else if (m.lz.len >= 3)  {
			writefln("LZ (%d) : %d", m.lz.offset, m.lz.len);
			m.next(m.lz.len);
		}
		// Uncompressed
		else {
			writefln("BYTE(%02X)", m.c);
			m.next(1);
		}
	}
}
