package brave.formats;

import haxe.io.BytesBuffer;
import haxe.Log;
import nme.errors.Error;
import nme.utils.ByteArray;
import nme.utils.Endian;
import nme.Vector;

/**
 * ...
 * @author soywiz
 */

class LZ 
{
	static inline var N = 4096;
	static inline var F = 16;
	static inline var THRESHOLD = 3;
	
	private function new() {
		
	}

	/**
	 * 
	 * @param	input
	 * @return
	 */
	static public function decode(input:ByteArray):ByteArray
	{
		var output = new ByteArray();
		output.endian = Endian.LITTLE_ENDIAN;
		input.endian = Endian.LITTLE_ENDIAN;
		input.position = 0;
		//Log.trace(input.bytesAvailable);
		if (input.readUTFBytes(4) != "SZDD") throw(new Error("Not a LZ stream"));
		input.readUnsignedInt();
		input.readUnsignedShort();
		var outputSize = input.readUnsignedInt();
		var buffer:Vector<Int> = new Vector<Int>();
		var i:Int = N - F;
		for (n in 0 ... N) buffer.push(0);
		
		while (input.bytesAvailable > 0) {
			var bits = (input.readUnsignedByte()) | 0x100;
			
			//Log.trace(bits);
			
			while (bits != 1)
			{
				var currentBit = ((bits & 1) != 0);
				bits >>= 1;
				
				//Log.trace("Current: " + bits + ":" + currentBit);

				if (currentBit)
				{
					output.writeByte(buffer[i] = input.readUnsignedByte());
					i = (i + 1) & (N - 1);
				}
				else
				{
					if (input.bytesAvailable == 0) break;
					var j = input.readUnsignedByte();
					var len = input.readUnsignedByte();
					j += (len & 0xF0) << 4;
					len = (len & 15) + 3;
					while (len-- > 0)
					{
						output.writeByte(buffer[i] = buffer[j]);
						j = (j + 1) & (N - 1);
						i = (i + 1) & (N - 1);
					}
				}
			}
		}
		
		output.position = 0;
		
		return output;
	}
}