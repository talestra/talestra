package brave.formats;

import brave.ByteUtils;
import haxe.io.Bytes;
import nme.display.BitmapData;
import nme.errors.Error;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author soywiz
 */

class BraveImage 
{
	/**
	 * 
	 */
	public var bitmapData:BitmapData;

	/**
	 * 
	 */
	public function new() 
	{
		
	}
	
	static private var decodeImageKey:Array<Int> = [
		0x84, 0x41, 0xDE, 0x48, 0x08, 0xCF, 0xCF, 0x6F, 0x62, 0x51, 0x64, 0xDF, 0x41, 0xDF, 0xE2, 0xE1
	];
	
	/**
	 * 
	 * @param	v
	 * @param	offset
	 * @param	count
	 * @param	to
	 * @return
	 */
	static private inline function extractScale(v:Int, offset:Int, count:Int, to:Int):Int
	{
		var mask:Int = ((1 << count) - 1);
		return cast((((v >> offset) & mask) * to) / mask);
	}
	
	static private function decryptChunk(input:ByteArray, key:Bytes):ByteArray {
		var output:ByteArray = new ByteArray();
		output.endian = Endian.LITTLE_ENDIAN;
		
		for (n in 0 ... input.length) {
			output.writeByte(Decrypt.decryptPrimitive(input.readByte(), key.get(n % key.length)));
		}
		
		output.position = 0;
		return output;
	}
	
	/**
	 * 
	 * @param	data
	 */
	@:noStack public function load(dataCompressed:ByteArray):Void
	{
		var data:ByteArray = LZ.decode(dataCompressed);
		if (data.readUTFBytes(13) != "(C)CROWD ARPG") throw (new Error("Invalid file"));
		data.readByte();
		var key:ByteArray = new ByteArray();
		var header:ByteArray = new ByteArray();
		var dummy:ByteArray = new ByteArray();
		
		data.endian = Endian.LITTLE_ENDIAN;
		key.endian = Endian.LITTLE_ENDIAN;
		header.endian = Endian.LITTLE_ENDIAN;
		dummy.endian = Endian.LITTLE_ENDIAN;
		
		data.readBytes(key, 0, 8);
		data.readBytes(header, 0, 16);
		
		header = decryptChunk(header, ByteUtils.ArrayToByteArray(decodeImageKey));
		header = decryptChunk(header, ByteUtils.ByteArrayToBytes(key));
		//for (n in 0 ... 0x10) header[n] = Decrypt.decryptPrimitive(header[n], decodeImageKey[n]);
		//for (n in 0 ... 0x10) header[n] = Decrypt.decryptPrimitive(header[n], key[n % 8]);
		
		var width:Int = header.readInt();
		var height:Int = header.readInt();
		var skip:Int = header.readInt();
		
		data.readBytes(dummy, 0, skip);
		
		this.bitmapData = new BitmapData(width, height);
		
		//data.position;
		
		var rgba:ByteArray = new ByteArray();
		//var n:Int = 0;
		//rgba.length = 4 * width * height;
		
		for (y in 0 ... height) {
			for (x in 0 ... width) {
				var pixelData:Int = data.readUnsignedShort();
				var b:Int = extractScale(pixelData, 0, 5, 0xFF);
				var g:Int = extractScale(pixelData, 5, 6, 0xFF);
				var r:Int = extractScale(pixelData, 11, 5, 0xFF);
				var a:Int = 0xFF;
				if ((r == 0xFF) && (g == 0x00) && (b == 0xFF))
				{
					r = g = b = a = 0x00;
				}
				rgba.writeByte(a);
				rgba.writeByte(r);
				rgba.writeByte(g);
				rgba.writeByte(b);
			}
		}
		
		rgba.position = 0;
		
		this.bitmapData.setPixels(new Rectangle(0, 0, width, height), rgba);
	}
}