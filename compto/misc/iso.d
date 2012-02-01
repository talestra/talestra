import std.stdio;
import std.file;
import std.stream;
import std.string;
import std.intrinsic;

class Sector {
	static uint LSN(ubyte minute, ubyte second, ubyte frame) {
		return (minute * 60 + (second - 2)) * 75 + frame;
	}
	
	static void fromLSN(uint lsn, out ubyte minute, out ubyte second, out ubyte frame) {
		uint clsn = lsn + 75 * 2;
		frame  = clsn % 75; clsn /= 75;
		second = clsn % 60; clsn /= 60;
		minute = clsn;
	}
	
	static ubyte[] Generate(ubyte[] data, ubyte[] _data, ulong lsn, int mode, int form = 0, bool EOR = false, bool EOF = false) in {
		assert(data.length == 0x930);
	} body {
		ubyte minute, second, frame;
		fromLSN(lsn, minute, second, frame);
	
		static const ubyte rs_l12_alog[255] = [1, 2, 4, 8,16,32,64,128,29,58,116,232,205,135,19,38,76,152,45,90,180,117,234,201,143, 3, 6,12,24,48,96,192,157,39,78,156,37,74,148,53,106,212,181,119,238,193,159,35,70,140, 5,10,20,40,80,160,93,186,105,210,185,111,222,161,95,190,97,194,153,47,94,188,101,202,137,15,30,60,120,240,253,231,211,187,107,214,177,127,254,225,223,163,91,182,113,226,217,175,67,134,17,34,68,136,13,26,52,104,208,189,103,206,129,31,62,124,248,237,199,147,59,118,236,197,151,51,102,204,133,23,46,92,184,109,218,169,79,158,33,66,132,21,42,84,168,77,154,41,82,164,85,170,73,146,57,114,228,213,183,115,230,209,191,99,198,145,63,126,252,229,215,179,123,246,241,255,227,219,171,75,150,49,98,196,149,55,110,220,165,87,174,65,130,25,50,100,200,141, 7,14,28,56,112,224,221,167,83,166,81,162,89,178,121,242,249,239,195,155,43,86,172,69,138, 9,18,36,72,144,61,122,244,245,247,243,251,235,203,139,11,22,44,88,176,125,250,233,207,131,27,54,108,216,173,71,142];
		static const ubyte rs_l12_log [256] = [0, 0, 1,25, 2,50,26,198, 3,223,51,238,27,104,199,75, 4,100,224,14,52,141,239,129,28,193,105,248,200, 8,76,113, 5,138,101,47,225,36,15,33,53,147,142,218,240,18,130,69,29,181,194,125,106,39,249,185,201,154, 9,120,77,228,114,166, 6,191,139,98,102,221,48,253,226,152,37,179,16,145,34,136,54,208,148,206,143,150,219,189,241,210,19,92,131,56,70,64,30,66,182,163,195,72,126,110,107,58,40,84,250,133,186,61,202,94,155,159,10,21,121,43,78,212,229,172,115,243,167,87, 7,112,192,247,140,128,99,13,103,74,222,237,49,197,254,24,227,165,153,119,38,184,180,124,17,68,146,217,35,32,137,46,55,63,209,91,149,188,207,205,144,135,151,178,220,252,190,97,242,86,211,171,20,42,93,158,132,60,57,83,71,109,65,162,31,45,67,216,183,123,164,118,196,23,73,236,127,12,111,246,108,161,59,82,41,157,85,170,251,96,134,177,187,204,62,90,203,89,95,176,156,169,160,81,11,245,22,235,122,117,44,215,79,174,213,233,230,231,173,232,116,214,244,234,168,80,88,175];
		static const ubyte DQ[2][43] = [[190,96,250,132,59,81,159,154,200,7,111,245,10,20,41,156,168,79,173,231,229,171,210,240,17,67,215,43,120,8,199,74,102,220,251,95,175,87,166,113,75,198,25], [97,251,133,60,82,160,155,201,8,112,246,11,21,42,157,169,80,174,232,230,172,211,241,18,68,216,44,121,9,200,75,103,221,252,96,176,88,167,114,76,199,26,1]];
		static const ubyte DP[2][24] = [[231,229,171,210,240,17,67,215,43,120,8,199,74,102,220,251,95,175,87,166,113,75,198,25], [230,172,211,241,18,68,216,44,121,9,200,75,103,221,252,96,176,88,167,114,76,199,26,1]];
		static const uint  EDC_crctable[0x100] = [0x00000000, 0x90910101, 0x91210201, 0x01B00300, 0x92410401, 0x02D00500, 0x03600600, 0x93F10701, 0x94810801, 0x04100900, 0x05A00A00, 0x95310B01, 0x06C00C00, 0x96510D01, 0x97E10E01, 0x07700F00, 0x99011001, 0x09901100, 0x08201200, 0x98B11301, 0x0B401400, 0x9BD11501, 0x9A611601, 0x0AF01700, 0x0D801800, 0x9D111901, 0x9CA11A01, 0x0C301B00, 0x9FC11C01, 0x0F501D00, 0x0EE01E00, 0x9E711F01, 0x82012001, 0x12902100, 0x13202200, 0x83B12301, 0x10402400, 0x80D12501, 0x81612601, 0x11F02700, 0x16802800, 0x86112901, 0x87A12A01, 0x17302B00, 0x84C12C01, 0x14502D00, 0x15E02E00, 0x85712F01, 0x1B003000, 0x8B913101, 0x8A213201, 0x1AB03300, 0x89413401, 0x19D03500, 0x18603600, 0x88F13701, 0x8F813801, 0x1F103900, 0x1EA03A00, 0x8E313B01, 0x1DC03C00, 0x8D513D01, 0x8CE13E01, 0x1C703F00, 0xB4014001, 0x24904100, 0x25204200, 0xB5B14301, 0x26404400, 0xB6D14501, 0xB7614601, 0x27F04700, 0x20804800, 0xB0114901, 0xB1A14A01, 0x21304B00, 0xB2C14C01, 0x22504D00, 0x23E04E00, 0xB3714F01, 0x2D005000, 0xBD915101, 0xBC215201, 0x2CB05300, 0xBF415401, 0x2FD05500, 0x2E605600, 0xBEF15701, 0xB9815801, 0x29105900, 0x28A05A00, 0xB8315B01, 0x2BC05C00, 0xBB515D01, 0xBAE15E01, 0x2A705F00, 0x36006000, 0xA6916101, 0xA7216201, 0x37B06300, 0xA4416401, 0x34D06500, 0x35606600, 0xA5F16701, 0xA2816801, 0x32106900, 0x33A06A00, 0xA3316B01, 0x30C06C00, 0xA0516D01, 0xA1E16E01, 0x31706F00, 0xAF017001, 0x3F907100, 0x3E207200, 0xAEB17301, 0x3D407400, 0xADD17501, 0xAC617601, 0x3CF07700, 0x3B807800, 0xAB117901, 0xAAA17A01, 0x3A307B00, 0xA9C17C01, 0x39507D00, 0x38E07E00, 0xA8717F01, 0xD8018001, 0x48908100, 0x49208200, 0xD9B18301, 0x4A408400, 0xDAD18501, 0xDB618601, 0x4BF08700, 0x4C808800, 0xDC118901, 0xDDA18A01, 0x4D308B00, 0xDEC18C01, 0x4E508D00, 0x4FE08E00, 0xDF718F01, 0x41009000, 0xD1919101, 0xD0219201, 0x40B09300, 0xD3419401, 0x43D09500, 0x42609600, 0xD2F19701, 0xD5819801, 0x45109900, 0x44A09A00, 0xD4319B01, 0x47C09C00, 0xD7519D01, 0xD6E19E01, 0x46709F00, 0x5A00A000, 0xCA91A101, 0xCB21A201, 0x5BB0A300, 0xC841A401, 0x58D0A500, 0x5960A600, 0xC9F1A701, 0xCE81A801, 0x5E10A900, 0x5FA0AA00, 0xCF31AB01, 0x5CC0AC00, 0xCC51AD01, 0xCDE1AE01, 0x5D70AF00, 0xC301B001, 0x5390B100, 0x5220B200, 0xC2B1B301, 0x5140B400, 0xC1D1B501, 0xC061B601, 0x50F0B700, 0x5780B800, 0xC711B901, 0xC6A1BA01, 0x5630BB00, 0xC5C1BC01, 0x5550BD00, 0x54E0BE00, 0xC471BF01, 0x6C00C000, 0xFC91C101, 0xFD21C201, 0x6DB0C300, 0xFE41C401, 0x6ED0C500, 0x6F60C600, 0xFFF1C701, 0xF881C801, 0x6810C900, 0x69A0CA00, 0xF931CB01, 0x6AC0CC00, 0xFA51CD01, 0xFBE1CE01, 0x6B70CF00, 0xF501D001, 0x6590D100, 0x6420D200, 0xF4B1D301, 0x6740D400, 0xF7D1D501, 0xF661D601, 0x66F0D700, 0x6180D800, 0xF111D901, 0xF0A1DA01, 0x6030DB00, 0xF3C1DC01, 0x6350DD00, 0x62E0DE00, 0xF271DF01, 0xEE01E001, 0x7E90E100, 0x7F20E200, 0xEFB1E301, 0x7C40E400, 0xECD1E501, 0xED61E601, 0x7DF0E700, 0x7A80E800, 0xEA11E901, 0xEBA1EA01, 0x7B30EB00, 0xE8C1EC01, 0x7850ED00, 0x79E0EE00, 0xE971EF01, 0x7700F000, 0xE791F101, 0xE621F201, 0x76B0F300, 0xE541F401, 0x75D0F500, 0x7460F600, 0xE4F1F701, 0xE381F801, 0x7310F900, 0x72A0FA00, 0xE231FB01, 0x71C0FC00, 0xE151FD01, 0xE0E1FE01, 0x7070FF00];

		static const uint RS_L12_BITS = 8;
		static const uint L2_P = 43 * 2 * 2;
		static const uint L2_Q = 26 * 2 * 2;
		
		void SetECC_Q(ubyte[] _data, ubyte[] _output) in {
			assert(_data.length == 4 + 0x800 + 4 + 8 + L2_P);
			assert(_output.length == L2_Q);	
		} body {
			ubyte* output = _output.ptr;
			
			for (int j = 0; j < 26; j++, output += 2) for (int i = 0; i < 43; i++) for (int n = 0; n < 2; n++) {
				ubyte cdata = _data[(j * 43 * 2 + i * 2 * 44 + n) % (4 + 0x800 + 4 + 8 + L2_P)];
				if (cdata == 0) continue;
				
				int base = rs_l12_log[cdata];
				
				void process(int t) {
					uint sum = base + DQ[t][i];
					if (sum >= ((1 << RS_L12_BITS) - 1)) sum -= (1 << RS_L12_BITS) - 1;
					output[26 * 2 * t + n] ^= rs_l12_alog[sum];
				}
				
				process(0); process(1);
			}
		}

		void SetECC_P(ubyte[] _data, ubyte[] _output) 
		in {
			assert(_data.length == 43 * 24 * 2);
			assert(_output.length == L2_P);
		} body {
			ubyte* data   = _data.ptr;
			ubyte* output = _output.ptr;

			for (int j = 0; j < 43; j++, output += 2, data += 2) for (int i = 0; i < 24; i++) for (int n = 0; n < 2; n++) {
				ubyte cdata = data[i * 2 * 43 + n];
				if (cdata == 0) continue;
				
				uint base = rs_l12_log[cdata];
				
				void process(int t) {
					uint sum = base + DP[t][i];
					if (sum >= ((1 << RS_L12_BITS) - 1)) sum -= (1 << RS_L12_BITS) - 1;
					output[43 * 2 * t + n] ^= rs_l12_alog[sum];
				}				
				
				process(0); process(1);
			}
		}

		void SetAddress(ubyte[] data) in {
			assert(data.length == 4);
		} body {
			data[0] = minute;
			data[1] = second;
			data[2] = frame;
			data[3] = mode;
		}

		void SetSync(ubyte[] sync) in {
			assert(sync.length == 12);
		} body {
			sync[0..12] = cast(ubyte[])x"00FFFFFFFFFFFFFFFFFFFF00";
		}

		void SetEDC(ubyte[] edc, ubyte[] data) in {
			assert(edc.length == 4);
		} body  {
			uint edc_i = 0;
			foreach (c; data) edc_i = EDC_crctable[(edc_i ^ c) & 0xFF] ^ (edc_i >> 8);
			
			edc[0] = ((edc_i >>  0) & 0xFF);
			edc[1] = ((edc_i >>  8) & 0xFF);
			edc[2] = ((edc_i >> 16) & 0xFF);
			edc[3] = ((edc_i >> 24) & 0xFF);
		}
		
		void SetSubheader(ubyte[] data) in {
			assert(data.length == 8);
		} body {
			ubyte inf = 8 | (1 * EOR) | (128 * EOF);
			
			if (mode == 2 && form == 2) inf |= 32;

			data[0] = data[4] = 0;  // File Number
			data[1] = data[5] = 0;  // Channel Number
			data[2] = data[6] = inf;
			data[3] = data[7] = 0;  // Coding Info
		}

		// Sets SyncData
		SetSync(data[0..12]);

		// Sets SubHeader
		SetSubheader(data[0x10..0x18]);

		switch (mode) {
			default: throw(new Exception(format("Unimplemented Sector Mode %d", mode)));
			/*case 0: break;
			case 1:
				SetAddress(data[12..16]);
				SetEDC(data[0x810..0x810 + 4], data[0..0x810]);
				SetECC_P(data[12..12 + 2064], data[0x81C..0x8C8]);
				SetECC_Q(data[12..12 + 4 + 0x800 + 4 + 8 + L2_P], data[0x8C8..0x930]);
			break;*/
			case 2:
				if (form < 2) {
					// Copy data
					assert(_data.length == 0x800);
					data[0x18..0x18 + 0x800] = _data[0..0x800];
				}
				
				switch (form) {
					default: throw(new Exception(format("Unimplemented Sector Mode 2 Form %d", form)));
					case 0: break;
					case 1:
						// Sets EDC
						SetEDC(data[0x818..0x818 + 4], data[0x10..0x818]);
						// Sets ECC P+Q
						SetECC_P(data[12..12 + 2064], data[0x81C..0x8C8]);
						SetECC_Q(data[12..12 + 4 + 0x800 + 4 + 8 + L2_P], data[0x8C8..0x930]);
					break;
					case 2:
						// Copy Data
						assert(_data.length == 0x92C);
						data[0x18..0x18 + 0x92C] = _data[0..0x92C];
						// Sets EDC
						SetEDC(data[0x92C..0x92C + 4], data[0x10..0x92C]);
					break;
				}
				
				SetAddress(data[12..16]);
			break;
		}
		
		return data;
	}

	static ubyte[] ReadData(ubyte[] data) in {
		assert(data.length == 0x930);
		assert(data[15] <= 2);
	} body {
		if (data[0..12] != cast(ubyte[])x"00FFFFFFFFFFFFFFFFFFFF00") return data;
		
		switch (data[15]) {
			default: throw(new Exception(format("Unimplemented Sector Mode %d", data[15])));
			/*
			case 0: return [];
			case 1:
			break;
			*/
			case 2:
				// Mode 2
				if (data[0x10 + 3] & 32) {
					return data[0x18..0x18 + 0x92C];
				}
				// Mode 1
				else {
					return data[0x18..0x18 + 0x800];
				}
			break;
		}
	}
}

// ISO 9660

align(1) struct IsoDate {
	ubyte info[17]; // 8.4.26.1
}

static ulong s733(uint v) {
	return cast(ulong)v | ((cast(ulong)bswap(v)) << 32);
}

align(1) struct uint733 {
	union {
		struct { uint l; uint h; }
		ulong v;
	}
	
	void opAssign(uint v) {
		l = v;
		h = bswap(v);
	}
	
	int opCmp(uint733 z) {
		if (v < z.v) return -1;
		else if (v > z.v) return +1;
		return 0;
	}
	
	static uint733 opCall(uint v) {
		uint733 r;
		r.l = v;
		r.h = bswap(v);
		return r;
	}
	
	uint opCast() {
		return l;
	}
}

align(1) struct IsoDirectoryRecord {
	ubyte   Length;
    ubyte   ExtAttrLength;
	uint733 Extent;
	uint733 Size;
	ubyte   Date[7];
	ubyte   Flags;
	ubyte   FileUnitSize;
	ubyte   Interleave;
	uint    VolumeSequenceNumber;
	ubyte   NameLength;
	//ubyte   _Unused;
	//char    Name[0x100];
}

struct IsoVolumeDescriptor {
	ubyte Type;
	char Id[5];
	ubyte Version;
	ubyte Data[2041];
};

// 0x800 bytes (1 sector)
align(1) struct IsoPrimaryDescriptor {
	ubyte Type;
	char  Id[5];
	ubyte Version;
	ubyte _Unused1;
	char  SystemId[0x20];
	char  VolumeId[0x20];
	ulong _Unused2;
	ulong VolumeSpaceSize;
	ulong _Unused3[4];
	uint  VolumeSetSize;
	uint  VolumeSequenceNumber;
	uint  LogicalBlockSize;
	ulong PathTableSize;
	uint  Type1PathTable;
	uint  OptType1PathTable;
	uint  TypeMPathTable;
	uint  OptTypeMPathTable;
	IsoDirectoryRecord RootDirectoryRecord;
	ubyte _Unused3b;
	char  VolumeSetId[128];
	char  PublisherId[128];
	char  PreparerId[128];
	char  ApplicationId[128];
	char  CopyrightFileId[37];
	char  AbstractFileId[37];
	char  BibliographicFileId[37];
	IsoDate CreationDate;
	IsoDate ModificationDate;
	IsoDate ExpirationDate;
	IsoDate EffectiveDate;
	ubyte FileStructureVersion;
	ubyte _Unused4;
	ubyte ApplicationData[512];
	ubyte _Unused5[653];
};

static assert(IsoPrimaryDescriptor.sizeof == 0x800);

class IsoEntry {
	IsoDirectoryRecord *dr;
	IsoEntry[] childs;
	char[] name;
	IsoReader iso;

	bool directory() { return (dr.Flags & 2) != 0; }
	
	this(IsoReader iso, IsoDirectoryRecord *dr = null) {
		this.dr = dr ? dr : (new IsoDirectoryRecord);
		this.iso = iso;
	}

	void write(Stream s) {
		dr.Length = dr.sizeof + name.length;
		dr.NameLength = name.length;
		s.write(cast(ubyte[])(dr)[0..1]);
		s.writeString(name);
	}
	
	bool read(Stream s) {
		long spos = s.position;
		s.read(cast(ubyte[])((dr)[0..1]));
		if (dr.Length <= 0) return false;
		name = s.readString(dr.NameLength);
		s.position = spos + dr.Length;
		return true;
	}
}

class IsoWriter {
	Stream siso;
	
	int last_lsn = 0;
	
	this(Stream s) {
		this.siso = s;
	}
	
	int write(Stream s, int mode, int form = 0) {
		int r = last_lsn;
		writeAt(last_lsn, s, mode, form);
		return r;
	}
	
	void writeAt(int lsn, Stream s, int mode, int form = 0, bool EOR = false, bool EOF = false) {
		siso.position = lsn * 0x930;
		
		ubyte[0x930] data;
		int len = 0;

		if (mode == 2 && form == 1) {
			len = 0x800;
		} else if (mode == 2 && form == 2) {
			len = 0x92C;
		} else {
			throw(new Exception("Invalid Sector Mode/Form"));
		}

		while (!s.eof) {
			ubyte[0x930] _data;
			int rlen = s.read(_data[0..len]);
			Sector.Generate(data, _data[0..len], lsn, mode, form, EOR, EOF);
			siso.write(data);
			lsn++;
		}
		
		if (last_lsn < lsn) last_lsn = lsn;
	}
	
	void writeAtRaw(int lsn, Stream s) {
		siso.position = lsn * 0x930;
		
		while (!s.eof) {
			ubyte[0x930] _data;
			s.read(_data);
			if (_data[0..12] == cast(ubyte[])x"00FFFFFFFFFFFFFFFFFFFF00") {
				Sector.fromLSN(lsn, _data[12], _data[13], _data[14]);
			}
			siso.write(_data);
			lsn++;
		}
		
		if (last_lsn < lsn) last_lsn = lsn;
	}
	
	void copyLicense(IsoReader ir) {
		writeAtRaw(0, ir.rawLicense);
	}
	
	void writePrimaryDescriptor(IsoPrimaryDescriptor ipd) {
		writeAt(0x10, new MemoryStream(cast(ubyte[])(&ipd)[0..1]), 2, 1, true, false);
	}
	
	void writeIsoVolumeDescriptor() {
		IsoVolumeDescriptor ivd;
		ivd.Type = 0xFF;
		ivd.Id[0..5] = "CD001";
		ivd.Version = 0x01;
		writeAt(0x10, new MemoryStream(cast(ubyte[])(&ivd)[0..1]), 2, 1, true, true);
	}
}

class IsoReader {
	Stream siso;
	bool raw;
	IsoPrimaryDescriptor ipd;
	IsoEntry root;
	
	ubyte[] readAt(int lsn, void[] _data) { ubyte[] data = cast(ubyte[])_data;
		if (raw) {
			int offset;
			siso.position = lsn * 0x930;
			while (offset < data.length) {
				ubyte[0x930] zdata;
				int rlen = siso.read(zdata);
				if (rlen == 0) break;
				ubyte[] readed = Sector.ReadData(zdata);
				data[offset..offset + readed.length] = readed[0..readed.length];
				offset += readed.length;
			}
		} else {
			siso.position = lsn * 0x800;
			siso.read(data);
		}
		return data;
	}
	
	this(Stream s, bool raw = false) {
		this.siso = s;
		this.raw = raw;
		readAt(0x10, (&ipd)[0..1]);
		root = new IsoEntry(&ipd.RootDirectoryRecord);
		processDR(root);
	}
	
	Stream drData(IsoDirectoryRecord dr) {
		ubyte[] data; data.length = cast(uint)dr.Size;
		readAt(cast(uint)dr.Extent, data);
		return new MemoryStream(data);
	}
	
	void processDR(IsoEntry e) { IsoDirectoryRecord* dr = e.dr;
		Stream drs = drData(*e.dr);
		while (!drs.eof) {
			auto ce = new IsoEntry();
			if (!ce.read(drs)) break;
			e.childs ~= ce;
			writefln("%s", ce.name);
		}
		
		foreach (ce; e.childs) {
			if (!ce.name.length || ce.name[0] == 0 || ce.name[0] == 1) continue;
			if (ce.directory) processDR(ce);
		}
	}
	
	Stream rawLicense() {
		return new SliceStream(siso, 0, 0x9300);
	}
}

void main() {
	auto oiso = new IsoReader(new BufferedFile("e:/isos/psx/Tales of Destiny I.bin"), true);
	auto iso = new IsoWriter(new File("myiso.iso", FileMode.OutNew));
	//iso.writeAt(0, oiso.drData(oiso.ipd.RootDirectoryRecord), 2, 1);
	
	
	/*
	writefln(oiso.ipd.PublisherId);
	iso.copyLicense(oiso);
	iso.writePrimaryDescriptor(oiso.ipd);
	iso.writeIsoVolumeDescriptor();
	*/
	//iso.writeAt(0, new File("iso.d"), 2, 1);
	//writefln(Sector.LSN(0, 4, 0));
	/*
	ubyte[0x930] buffer;
	ubyte[0x800] data;
	write("out.dat", cast(void[])GenerateSector(buffer, data, 0, 2, 0, 2, 1));
	*/
}
