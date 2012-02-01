import std.stdio, std.string, std.file, std.stream, std.intrinsic;

//debug = comp_info;

final static ushort hash(ubyte[] data, int pos)
{
	return (pos < data.length - 3) ? (data[pos + 0] << 0) ^ (data[pos + 1] << 4) ^ (data[pos + 2] << 8) : 0;
}

ubyte[] compress(ubyte[] data)
{
	int[][1 << 16] hashes;
	ubyte[] data_out;
	ushort chash = hash(data, 0);
	int uncomp_len = 0;
	int comp_size = 0;
	int wpos;
	
	int writevariable(int vv, bool write = false)
	{
		int len = 0;
		ubyte v;
		while (vv) {
			v = vv & 0x7F;
			vv >>= 7;
			if (vv) v |= 0x80;
			if (write) data_out ~= v;
			len++;
		}
		return len;
	}
	
	int encodepos(int dist, int len, bool write = false)
	{
		int r = 0;
		r += writevariable(dist, write);
		r += writevariable(len, write);
		return r;
	}
	
	uint block_start = 0;
	uint block = (1 << 16);
	
	data_out = [0];

	for (wpos = 0; wpos < data.length;)
	{
		int maxlen = data.length - wpos;
		
		int skip = 1;
		int max_gain = 0, max_dist = 0, max_len = 0;
		int max_check = 0x100000;
		
		foreach_reverse (rpos; hashes[chash])
		{
			int dist = (wpos - rpos), len = 0;
			for (int n = 0; n < maxlen; n++, len++) if (data[wpos + n] != data[rpos + n]) break;
			int encode_len = encodepos(dist, len);
			int gain = len - encode_len;

			// Invalid encoding.
			if (encode_len < 0) continue;
			
			if (gain > max_gain)
			{
				max_gain = gain;
				max_dist = dist;
				max_len  = len;
			}
			if (max_check-- <= 0) break;
		}
		
		// Finished block.
		//writefln("%08X", block);
		if (block & (1 << 8))
		{
			//writefln("block");
			data_out[block_start] = (block & 0xFF);
			block_start = data_out.length;
			block = block.init;
			data_out ~= 0;
			debug (comp_info) writefln("----------------------------------------------------------");
		}

		if (max_gain > 2)
		{
			debug (comp_info) writefln("COMP(%d, %d)", max_dist, max_len);
			encodepos(max_dist, max_len, true);
			skip = max_len;
		}
		else
		{
			debug (comp_info) writefln("UNCOMP(%02X)", data[wpos]);
			data_out ~= data[wpos];
			block |= 0x80;
		}
		block >>= 1;
		debug (comp_info) writefln("CODE(%032b)\n", block);
		
		while (skip-- > 0)
		{
			hashes[chash] ~= wpos;
			chash = hash(data, wpos);
			wpos++;
		}
	}
	data_out[block_start] = (block & 0xFF);
	return data_out;
}

void main()
{
	char[] file_i = "black.img.dat";
	char[] file_o = file_i ~ ".c9";
	write(file_o, compress(cast(ubyte[])read(file_i)));
}