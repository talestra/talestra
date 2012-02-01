import std.stdio, std.file, std.stream;

T min(T)(T a, T b) { return (a <= b) ? a : b; }
T max(T)(T a, T b) { return (a >= b) ? a : b; }

/*
@TODO enable finding RLE with overlapping.
*/
class LZEncoder {
	ubyte[] data;
	uint[][ubyte[2]] patternPositions;
	int maxDistance = 0x1000;
	int maxLength = 0x1000;

	void encodeInit() {
	}
	
	void encodeFinish() {
	}
	
	void encodeUncompressed(uint start, uint end) {
		writefln("NORMAL ('%s')", cast(char[])data[start..end]);
	}
	
	void encodePattern(int currentPosition, int patternPosition, int patternLength) {
		writefln("PATTERN(%d, %d) : '%s'", patternPosition - currentPosition, patternLength, cast(char[])data[patternPosition..patternPosition + patternLength]);
	}

	int calculateWasteInLZ(uint currentPos, int findPosition, int findLength) {
		return 2;
	}

	bool findPattern(uint currentPos, ubyte[] find, out int findPosition, out int findLength) {
		if (find.length < 2) return false;
		ubyte[2] hash = find[0..2];
		findPosition = 0;
		findLength = 0;
		if (hash in patternPositions) {
			int findImproved = 0;
			foreach_reverse(currentFindPosition; patternPositions[hash]) {
				int distance = currentPos - currentFindPosition;
				if (distance > maxDistance) break;
			
				int maxCompare = min(
					data.length - currentFindPosition,
					find.length
				);
				int currentFindLength;
				for (currentFindLength = 0; currentFindLength < maxCompare; currentFindLength++) {
					if (data[currentFindPosition + currentFindLength] != find[currentFindLength]) break;
				}
				currentFindLength = min(currentFindLength, maxLength);
				
				int waste = calculateWasteInLZ(currentPos, currentFindPosition, currentFindLength);
				// Invalid position/length.
				if (waste < 0) continue;
				int currentImproved = currentFindLength - waste;
				
				if (currentImproved > findImproved) {
					findImproved = currentImproved;
					findLength   = currentFindLength;
					findPosition = currentFindPosition;
				}
			}
		}
		patternPositions[hash] ~= currentPos;
		return (findLength > 0);
	}
	
	void encode() {
		int findPosition, findLength;
		int normalStart = 0;
		int normalEnd = 0;
		void encodeUncompressedValid() {
			if (normalEnd == normalStart) return;
			encodeUncompressed(normalStart, normalEnd);
		}
		encodeInit();
		for (int n = 0; n < data.length; n++) {
			if (findPattern(n, data[n..$], findPosition, findLength)) {
				encodeUncompressedValid();
				encodePattern(n, findPosition, findLength);
				n += findLength - 1;
				normalEnd = normalStart = n + 1;
			} else {
				normalEnd++;
			}
		}
		encodeUncompressedValid();
		encodeFinish();
	}
}

class TalesLZEncoder : LZEncoder {
	const minLength = 2;
	int headerSize = 1 + 4 + 4;
	
	void setAttribs() {
		this.maxDistance = 0xFFF;
		this.maxLength = 0x11;
	}

	ubyte[] output;
	ubyte[] buffer;
	int code;
	
	void resetSet() {
		code = 0x100 << 8;
		buffer.length = 0;
	}
	
	void flushBuffer() {
		if (code != 1) {
			output ~= code & 0xFF;
			output ~= buffer;
			resetSet();
		}
	}

	void putData(bool compressed, ubyte[] data) {
		code = (code >> 1) | (compressed ? 0 : 0x80);
		buffer ~= data;
		if (code & 0x100) flushBuffer();
	}

	int calculateWasteInLZ(uint currentPos, int findPosition, int findLength) {
		return minLength;
	}
	
	void encodeInit() {
		setAttribs();
		output.length = headerSize;
		*cast(ubyte *)(output.ptr + 0) = 3;
		*cast(uint *)(output.ptr + 5) = data.length;
		resetSet();
	}

	void encodeFinish() {
		flushBuffer();
		*cast(uint *)(output.ptr + 1) = output.length - headerSize;
	}

	void encodeUncompressed(uint start, uint end) {
		foreach (c; data[start..end]) putData(false, [c]);
		//writefln("NORMAL ('%s')", cast(char[])data[start..end]);
	}
	
	void encodePattern(int currentPosition, int patternPosition, int patternLength) {
		//writefln("Length: %02X", patternLength);
		int patternPossitionDist = currentPosition - patternPosition;
		int sliceOffset = (patternPosition + 0xFEE + 1) & 0xFFF;
		//writefln("%08X", patternPossitionDist);
		putData(true, [
			sliceOffset & 0xFF,
			(((sliceOffset >> 4) & 0xf0) | ((patternLength - (minLength + 1)) & 0x0f))
		]);
		//writefln("PATTERN(%d, %d) : '%s'", patternPosition - currentPosition, patternLength, cast(char[])data[patternPosition..patternPosition + patternLength]);
	}
	
	public static Stream encodeStream(Stream input) {
		auto lz = new TalesLZEncoder;
		lz.data = cast(ubyte[])input.readString(input.size);
		lz.encode();
		return new MemoryStream(lz.output);
	}
}

/*
void main() {
	auto lz = new TalesLZEncoder();
	//std.file.read("lzsimple.d")
	//lz.data = cast(ubyte[])"Hola mundo, esto es una prueba. Para decir Hola.";
	lz.data = cast(ubyte[])std.file.read("lzsimple.d");
	lz.encode();
	std.file.write("out.bin", lz.output);
}
*/
