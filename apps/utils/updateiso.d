private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream, std.intrinsic;

template TSerialize(T) {
	ubyte[] TSerialize(T *t) {
		return (cast(ubyte *)t)[0..T.sizeof];
	}
}


// TODO
/*class SliceStreamNotClose : SliceStream {
}*/

void copyStream(Stream from, Stream to) {
	if (false) {
		ubyte[] temp; temp.length = 0x800 * 0x200 * 4;
		from.position = 0;
		uint toread = from.size;
		while (toread) {
			uint readed;
			//if (toread < temp.length) temp.length = toread;
			readed = from.read(temp);
			to.write(temp[0..readed]);
			//writefln("* %d", readed);
			toread -= readed;
			if (readed <= 0) break;
		}
		delete temp;
	} else {
		to.copyFrom(from);
	}
}

abstract class ContainerEntry {
	ContainerEntry parent;
	ContainerEntry[] childs;
	char[] name;
	Stream open () { throw(new Exception("'open' Not implemented")); }
	void close() { throw(new Exception("'close' Not implemented")); }

	char[] type() {
		return "";
	}

	void print() {
		writefln("%s('%s')", this, name);
	}

	void saveto(Stream s) {
		Stream cs = this.open();
		s.copyFrom(cs);
		s.flush();
		//this.close();
	}

	ubyte[] read() {
		ubyte[] ret;
		MemoryStream s = new MemoryStream();
		saveto(s);
		ret.length = s.data.length;
		ret[0..ret.length] = s.data[0..ret.length];
		delete s;
		return ret;
	}

	public void saveto(char[] s) {
		File f = new File(s, FileMode.OutNew);
		saveto(f);
		f.close();
	}

	void listex(char[] base = "") {
		print();
		foreach (child; childs) {
			if (!child.name) continue;
			writefln("'%s%s'", base, child.name);
			if (child.childs.length) child.list(format("%s/", child.name));
		}
	}

	void list(char[] base = "") {
		foreach (child; childs) {
			if (!child.name) continue;
			writefln("%s%s", base, child.name);
		}
	}

	void add(ContainerEntry ce) {
		childs ~= ce;
		ce.parent = this;
	}

	ContainerEntry opIndex(char[] name) {
		int p; if ((p = std.string.find(name, '/')) != -1) {
			return opIndex(name[0..p])[name[p + 1..name.length]];
		}

		if (name.length == 0) return this;

		foreach (child; childs) {
			//writefln(child.name);
			if (std.string.icmp(child.name, name) == 0) return cast(ContainerEntry)child;
		}
		throw(new Exception(format("File '%s' doesn't exists", name)));
	}

    int opApply(int delegate(inout ContainerEntry) dg) {
    	int result = 0;

		for (int n = 0; n < childs.length; n++) {
			result = dg(childs[n]);
			if (result) break;
		}

		return result;
    }

	// Reemplazamos un stream
	int replace(Stream from, bool limited = true) {
		//writefln("ContainerEntry.replace(%08X);", cast(uint)cast(uint *)this);
		Stream op = this.open();
		//writefln("%d", op.writeable);
		ulong start = op.position;

		copyStream(from, op);

		return op.position - start;
	}

	int replaceAt(Stream from, int skip = 0) {
		//writefln("ContainerEntry.replace(%08X);", cast(uint)cast(uint *)this);
		Stream op = this.open();
		//writefln("%d", op.writeable);
		ulong start = op.position;
		op.position = start + skip;
		copyStream(from, op);
		return op.position - start;
	}

	// Reemplazamos por un fichero
	void replace(char[] from, bool limited = true) {
		File f = new File(from, FileMode.In);
		replace(f, limited);
		f.close();
	}

	// Reemplazamos por un fichero
	void replaceAt(char[] from, int skip = 0) {
		File f = new File(from, FileMode.In);
		replaceAt(f, skip);
		f.close();
	}

	bool isFile() {
		return false;
	}
}

abstract class ContainerEntryWithStream : ContainerEntry {
	Stream stream;

	Stream rs;

	void setData(void[] data) {
		setStream(new MemoryStream(cast(ubyte[])data));
	}

	void setStream(Stream s) {
		//close();
		rs = s;
		s.position = 0;
	}

	Stream open() {
		if (rs) return rs;

		//writefln("ContainerEntry.open(%08X);", cast(uint)cast(uint *)this);
		if (stream && stream.isOpen) {
			//writefln("opened");
			stream.position = 0;
			return stream;
		}
		//writefln("realopen");
		return stream = realopen();
	}

	void close() {
		//writefln("ContainerEntry.close(%08X);", cast(uint)cast(uint *)this);
		if (stream && stream.isOpen) {
			//writefln("closd");
			stream.close();
		}
	}

	protected Stream realopen(bool limited = true) {
		throw(new Exception("realopen: Not Implemented (" ~ this.toString ~ ")"));
	}
}


// ISO 9660

align(1) struct IsoDate {
	ubyte info[17]; // 8.4.26.1
}

static ulong s733(uint v) {
	return cast(ulong)v | ((cast(ulong)bswap(v)) << 32);
}

align(1) struct IsoDirectoryRecord {
	ubyte   Length;
    ubyte   ExtAttrLength;
	ulong   Extent;
	ulong   Size;
	ubyte   Date[7];
	ubyte   Flags;
	ubyte   FileUnitSize;
	ubyte   Interleave;
	uint    VolumeSequenceNumber;
	ubyte   NameLength;
	//ubyte   _Unused;
	//char    Name[0x100];
}

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

void Dump(IsoDirectoryRecord idr) {
	writefln("IsoDirectoryRecord {");
	writefln("  Length:               %02X", idr.Length);
	writefln("  ExtAttrLength:        %02X", idr.ExtAttrLength);
	writefln("  Extent:               %08X", idr.Extent & 0xFFFFFFFF);
	writefln("  Size:                 %08X", idr.Size & 0xFFFFFFFF);
	writefln("  Date:                 [...]");
	writefln("  Flags:                %02X", idr.Flags);
	writefln("  FileUnitSize:         %02X", idr.FileUnitSize);
	writefln("  Interleave:           %02X", idr.Interleave);
	writefln("  VolumeSequenceNumber: %08X", idr.VolumeSequenceNumber);
	writefln("  NameLength:           %08X", idr.NameLength);
	writefln("}");
	writefln();
}

void Dump(IsoPrimaryDescriptor ipd) {
	writefln("IsoPrimaryDescriptor {");
	writefln("  Type:                 %02X",   ipd.Type);
	writefln("  ID:                   '%s'",   ipd.Id);
	writefln("  Version:              %02X",   ipd.Version);
	writefln("  SystemId:             '%s'",   ipd.SystemId);
	writefln("  VolumeId:             '%s'",   ipd.VolumeId);
	writefln("  VolumeSpaceSize:      %016X",  ipd.VolumeSpaceSize);
	writefln("  VolumeSetSize:        %08X",   ipd.VolumeSetSize);
	writefln("  VolumeSequenceNumber: %08X",   ipd.VolumeSequenceNumber);
	writefln("  LogicalBlockSize:     %08X",   ipd.LogicalBlockSize);
	writefln("  PathTableSize:        %016X",  ipd.PathTableSize);
	writefln("  Type1PathTable:       %08X",   ipd.Type1PathTable);
	writefln("  OptType1PathTable:    %08X",   ipd.OptType1PathTable);
	writefln("  TypeMPathTable:       %08X",   ipd.TypeMPathTable);
	writefln("  OptTypeMPathTable:    %08X",   ipd.OptTypeMPathTable);
	writefln("  RootDirectoryRecord:  [...]");
	Dump(ipd.RootDirectoryRecord);
	writefln("  VolumeSetId:          '%s'",   ipd.VolumeSetId);
	writefln("  PublisherId:          '%s'",   ipd.PublisherId);
	writefln("  PreparerId:           '%s'",   ipd.PreparerId);
	writefln("  ApplicationId:        '%s'",   ipd.ApplicationId);
	writefln("  CopyrightFileId:      '%s'",   ipd.CopyrightFileId);
	writefln("  AbstractFileId:       '%s'",   ipd.AbstractFileId);
	writefln("  BibliographicFileId:  '%s'",   ipd.BibliographicFileId);
	writefln("  CreationDate:         [...]");
	writefln("  ModificationDate:     [...]");
	writefln("  ExpirationDate:       [...]");
	writefln("  EffectiveDate:        [...]");
	writefln("  FileStructureVersion: %02X",   ipd.FileStructureVersion);
	writefln("}");
	writefln();
}

class IsoEntry : ContainerEntryWithStream {
	Stream drstream;
	IsoDirectoryRecord dr;
	Iso iso;
	uint udf_extent;

	char[] fullname;

	override void print() {
		writefln(this.toString);
		Dump(dr);
	}

	// Escribimos el DirectoryRecord
	void writedr() {
		drstream.position = 0;
		drstream.write(TSerialize(&dr));

		// Actualizamos tambien el udf
		if (udf_extent) {
			//writefln("UDF: %08X", udf_extent);
			Stream udfs = new SliceStream(iso.stream, 0x800 * udf_extent, 0x800 * (udf_extent + 1));
			udfs.position = 0x38;
			udfs.write(cast(uint)(dr.Size & 0xFFFFFFFF));
			udfs.position = 0x134;
			//writefln("%08X", dr.Size & 0xFFFFFFFF);
			udfs.write(cast(uint)(dr.Size & 0xFFFFFFFF));
			udfs.write(cast(uint)((dr.Extent & 0xFFFFFFFF) - 262));
			//writefln("patching udf");
		}
	}

	// Cantidad de sectores necesarios para almacenar
	uint Sectors() {
		return dr.Size / 0x800;
	}

	override int replace(Stream from, bool limited = true) {
		Stream op = iso.openDirectoryRecord(dr, limited);
		ulong start = op.position;
		//op.copyFrom(from);
		copyStream(from, op);
		uint length = op.position - start;
		op.close();
		dr.Size = s733(length);
		writedr();
		return length;
	}

	override int replaceAt(Stream from, int skip = 0) {
		Stream op = iso.openDirectoryRecord(dr, false);
		ulong start = op.position;
		op.position = start + skip;
		//op.copyFrom(from);
		copyStream(from, op);
		uint length = op.position - start;
		op.close();
		dr.Size = s733(length);
		writedr();
		return length;
	}

	void swap(IsoEntry ie) {
		if (ie.iso != this.iso) throw(new Exception("Only can swap entries in same iso file"));

		int TempExtent, TempSize;

		TempExtent = ie.dr.Extent;
		TempSize   = ie.dr.Size;

		ie.dr.Extent = this.dr.Extent;
		ie.dr.Size   = this.dr.Size;

		this.dr.Extent = TempExtent;
		this.dr.Size   = TempSize;

		this.writedr();
		ie.writedr();
	}

	void use(IsoEntry ie) {
		if (ie.iso != this.iso) throw(new Exception("Only can swap entries in same iso file"));

		this.dr.Extent = ie.dr.Extent;
		this.dr.Size   = ie.dr.Size;

		this.writedr();
	}

	/*override protected Stream realopen(bool limited = true) {
		throw(new Exception(""));
	}*/
}

class IsoDirectory : IsoEntry {
	Stream open() {
		throw(new Exception(""));
	}

	void clearFiles() {
		foreach (ce; this) {
			IsoEntry ie = cast(IsoEntry)ce;
			//writefln("%s - %s", ie.name, ie.classinfo.name);
			if (ie.classinfo.name == "tales.scont.iso.IsoFile") {
				//ie.dr.Extent = s733(iso.writeDatasector);
				ie.dr.Extent = s733(0);
				ie.dr.Size   = s733(0);
				//writefln(ie.name);
				ie.writedr();
			} else if (ie.classinfo.name == "tales.scont.iso.IsoDirectory") {
				if (ie != this) (cast(IsoDirectory)ie).clearFiles();
			}
		}
	}
}

class IsoFile : IsoEntry {
	uint size;

	override bool isFile() {
		return true;
	}

	override Stream realopen(bool limited = true) {
		return iso.openDirectoryRecord(dr);
	}
}

class SliceStreamNoClose : SliceStream {
	this(Stream s, ulong pos, ulong len) { super(s, pos, len); }
	this(Stream s, ulong pos) { super(s, pos); }

	override void close() { Stream.close(); }
}

class Iso : IsoDirectory {
	IsoPrimaryDescriptor ipd;
	Stream stream;
	uint position = 0;
	uint datastart = 0xFFFFFFFF;
	uint firstDatasector = 0xFFFFFFFF;
	uint lastDatasector = 0x00000000;
	uint writeDatasector = 0x00000000;

	Iso copyIsoStructure(Stream s) {
		Iso iso;
		//writefln(firstDatasector);

		if (firstDatasector > 3000) throw(new Exception("ERROR!"));

		//s.copyFrom(new SliceStream(stream, 0, (cast(ulong)firstDatasector) * 0x800));
		//writefln(firstDatasector);
		copyStream(new SliceStream(stream, 0, (cast(ulong)firstDatasector) * 0x800), s);
		s.position = 0;

		iso = new Iso(s);
		iso.writeDatasector = iso.firstDatasector;

		iso.clearFiles();

		return iso;
	}

	void copyUnrecreatedFiles(Iso iso, bool show = true) {
		//writefln("copyUnrecreatedFiles()");
		foreach (ce; this) {
			IsoEntry ie = cast(IsoEntry)ce;
			if (ie.dr.Extent) continue;

			if (show) printf("%s...", toStringz(ce.name));

			recreateFile(ie, iso[ie.name].open, 5);	iso[ie.name].close();

			if (show) printf("Ok\n");
		}
		stream.flush();
	}

	void recreateFile(ContainerEntry ce) {
		IsoEntry e  = cast(IsoEntry)ce;
		e.dr.Extent = s733(1);
		e.dr.Size   = s733(0);
		e.writedr();
	}

	void recreateFile(ContainerEntry ce, char[] n, int addVoidSectors = 0) {
		Stream s = new File(n, FileMode.In);
		recreateFile(ce, s, addVoidSectors);
		s.close();
	}

	void recreateFile(ContainerEntry ce, Stream s, int addVoidSectors = 0) {
		s.position = 0;
		//printf("Available: %d\n", cast(int)(s.available & 0xFFFFFFFF));
		Stream w = startFileCreate(ce);
		uint pos = w.position;

		uint available = s.available;

		copyStream(s, w);
		//w.copyFrom(s);
		w.position = pos + available;

		//printf("Z: %d | (%d)\n", cast(int)(w.position - pos), s.available);
		endFileCreate(addVoidSectors);
		//printf("\n");
		/*
		IsoEntry e = cast(IsoEntry)ce;
		stream.position = (cast(ulong)writeDatasector) * 0x800;
		ulong start = stream.position;
		stream.copyFrom(s);
		ulong size = stream.position - start;

		e.dr.Extent = s733(writeDatasector);
		e.dr.Size   = s733(size);

		writefln("%08X - %08X", writeDatasector, size);

		e.writedr();

		writeDatasector += sectors(size) + addsect;
		*/
	}

	ContainerEntry oce; // OpenedContainerEntry
	Stream writing;
	Stream startFileCreate(ContainerEntry ce) {
		oce = ce;
		if ((cast(IsoEntry)ce).iso != this) throw(new Exception("Only can update entries in same iso file"));
		//printf("{START: %08X}\n", writeDatasector);
		uint spos = (cast(ulong)writeDatasector) * 0x800;
		{
			stream.seek(0, SeekPos.End);
			ubyte[] temp; temp.length = 0x800 * 0x100;
			while (stream.position < spos) {
				if (spos - stream.position > temp.length) {
					stream.write(temp);
				} else {
					stream.write(temp[0..spos - stream.position]);
					//stream.position - spos
				}
			}
		}
		writing = new SliceStream(stream, spos);
		return writing;
	}

	void endFileCreate(int addVoidSectors = 0) {
		writing.position = 0; uint length = writing.available;
		/*
		uint length = writing.position;
		writing.position = 0;
		if (writing.available > length) length = writing.available;
		writing.position = length;
		*/

		//printf("{LENGTH: %08X(%08X)}", length, length / 0x800);

		IsoEntry e = cast(IsoEntry)oce;
		e.dr.Extent = s733(writeDatasector);
		e.dr.Size = s733(length);
		e.writedr();
		writeDatasector += sectors(length) + addVoidSectors;

		//printf("| {END: %08X}\n", writeDatasector);

		if (length % 0x800) {
			stream.position = (cast(ulong)writeDatasector) * 0x800 - 1;
			stream.write(cast(ubyte)0);
		}
	}


	override void print() {
		Dump(ipd);
	}

	static uint sectors(ulong size) {
		uint sect = (size / 0x800);
		if ((size % 0x800) != 0) sect++;
		return sect;
	}

	void processFileDR(IsoDirectoryRecord dr) {
		uint ssect = (dr.Extent & 0xFFFFFFFF);
		uint size  = (dr.Size   & 0xFFFFFFFF);
		uint sectl = sectors(size);
		uint esect = ssect + sectl;

		//writefln("%08X", ssect);

		if (ssect < firstDatasector) firstDatasector = ssect;
		if (esect > lastDatasector ) lastDatasector  = esect;
	}

	Stream openDirectoryRecord(IsoDirectoryRecord dr, bool limited = true) {
		ulong from = getSectorPos(dr.Extent & 0xFFFFFFFF);
		uint size  = (dr.Size & 0xFFFFFFFF);
		return limited ? (new SliceStreamNoClose(stream, from, from + size)) : (new SliceStreamNoClose(stream, from));
	}

	ubyte[] readSector(uint sector) {
		ubyte[] ret; ret.length = 0x800;
		stream.position = getSectorPos(sector);
		stream.read(ret);
		return ret;
	}

	private ulong getSectorPos(uint sector) {
		return (cast(ulong)sector) * 0x800;
	}

	private void processDirectory(IsoDirectory id) {
		IsoDirectoryRecord dr;
		IsoDirectoryRecord bdr = id.dr;
		int cp;

		stream.position = getSectorPos(bdr.Extent);

		char[] getRealName(char[] s) {
			if (s.length > 2 && s[0..s.length - 2] == ";1") return s[0..s.length - 2];
			return s;
		}

		while (true) {
		//for (int n = 0; n < 100; n++) {
			char[] name;
			Stream drstream;

			if ((stream.position / 0x800) != ((stream.position + dr.sizeof + 32) / 0x800)) {
				stream.position = ((stream.position + dr.sizeof + 32) / 0x800) * 0x800;
			}

			drstream = new SliceStream(stream, stream.position, dr.sizeof);

			stream.read(TSerialize(&dr));

			if (!dr.Length) break;

			name.length = dr.Length - dr.sizeof;
			stream.read(cast(ubyte[])name);
			name.length = dr.NameLength;

			//writefln(":'%s'", name);
			//Dump(dr);

			//processDR(dr);

			if (dr.NameLength && name[0] != 0 && name[0] != 1) {
				// Directorio
				if (dr.Flags & 2) {
					IsoDirectory cid = new IsoDirectory();
					cid.drstream = drstream;
					cid.iso = this;
					cid.dr = dr;
					id.add(cid);
					cid.name = getRealName(name);

					uint bp = stream.position;
					{
						processDirectory(cid);
					}
					stream.position = bp;
				}
				// Fichero
				else {
					processFileDR(dr);
					if (cast(uint)dr.Extent < datastart) datastart = dr.Extent;
					IsoFile cif = new IsoFile();
					cif.drstream = drstream;
					cif.iso = this;
					cif.dr = dr;
					cif.size = dr.Size;
					id.add(cif);
					cif.name = getRealName(name);
					//Dump(dr);
				}
			} else {
				IsoEntry ie = new IsoEntry();
				ie.iso = this;
				ie.dr = dr;
				id.add(ie);
				//Dump(dr);
			}
		}
	}

	this(Stream s) {
		ubyte magic[4];
		//stream = new PatchedStream(s);
		stream = s;

		stream.position = 0;

		stream.read(magic);

		if (cast(char[])magic == "CVMH") {
			stream.position = 0;
			stream = new SliceStream(stream, 0x1800);
		}

		stream.position = getSectorPos(0x10);
		stream.read(TSerialize(&ipd));

		this.dr = ipd.RootDirectoryRecord;
		this.name = "/";

		processDirectory(this);

		writeDatasector = lastDatasector;

		//try { _udf_check(); } catch (Exception e) { }
	}

	this(char[] s, bool readonly = false) {
		File f;

		try {
			f = new File(s, readonly ? FileMode.In : (FileMode.In | FileMode.Out));
		} catch (Exception e) {
			f = new File(s, FileMode.In);
		}

		this(f);
	}

	private this() { }

	void copyIsoInfo(Iso from) {
		ubyte[0x800 * 0x10] data;
		int fromposition = from.stream.position; scope(exit) { from.stream.position = fromposition; }
		from.stream.position = 0;
		from.stream.read(data);
		this.stream.write(data);
		this.ipd = from.ipd;
		this.position = 0x800 * 0x11;
		this.datastart = from.datastart;
	}

	static Iso create(Stream s) {
		Iso iso = new Iso;
		iso.stream = s;
		return iso;
	}

	void swap(char[] a, char[] b) {
		(cast(IsoEntry)this[a]).swap(cast(IsoEntry)this[b]);
	}

	void use(char[] a, char[] b) {
		(cast(IsoEntry)this[a]).use(cast(IsoEntry)this[b]);
	}

	//void _udf_test() {
	void _udf_check() {
		char[] decodeDstringUDF(ubyte[] s) {
			char[] r;
			if (s.length) {
				ubyte bits = s[0];
				switch (bits) {
					case 8:
						for (int n = 1; n < s.length; n++) r ~= s[n];
					break;
					case 16:
						for (int n = 2; n < s.length; n += 2) r ~= s[n];
					break;
				}
			}
			return r;
		}
		/*
		struct FileIdentifierDescriptor { // ISO 13346 4/14.4
			struct tag DescriptorTag;
			Uint16 FileVersionNumber;
			Uint8 FileCharacteristics;
			Uint8 LengthofFileIdentifier;
			struct long_ad ICB ;
		}
		*/

		stream.position = 0x800 * 264;

		int count = 0;

		while (true) {
			uint ICB_length, ICB_extent;
			ubyte FileCharacteristics, LengthofFileIdentifier;
			ushort FileVersionNumber, LengthofImplementationUse;

			// Padding
			while (stream.position % 4) stream.position = stream.position + 1;

			// Escapamos el tag
			stream.seek(0x10, SeekPos.Current);

			stream.read(FileVersionNumber);
			if (FileVersionNumber != 0x01) {
				//writefln("%08X : %04X", stream.position - 2, FileVersionNumber);
				break;
			}

			//writefln("%08X", stream.position - 2);

			stream.read(FileCharacteristics);
			stream.read(LengthofFileIdentifier);
			stream.read(ICB_length);
			stream.read(ICB_extent);
			stream.seek(8, SeekPos.Current);

			// Escapamos la implementacion
			stream.read(LengthofImplementationUse);
			stream.seek(LengthofImplementationUse, SeekPos.Current);

			ubyte[] name; name.length = LengthofFileIdentifier;
			stream.read(name);

			if (name.length) {
				//writefln("%s : %d", decodeDstringUDF(name), ICB_length);
				(cast(IsoEntry)this[decodeDstringUDF(name)]).udf_extent = ICB_extent + 262;
				//writefln("%s", decodeDstringUDF(name));
				//writefln(this[decodeDstringUDF(name)]);
			}
		}
	}
}

int main(char[][] args) {
	Iso iso = new Iso("p:/iso/haruhi.iso");
	//iso.list();
	iso["PSP_GAME/USRDIR/data/script/s_0000ess0.dat"].saveto("zztemp");
	//m_isomap.swap("TESTMAP.PKB", "CAP_I06_05.PKB");
	return 0;
}