package brave;
import haxe.io.Bytes;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author 
 */

class ByteUtils 
{
	@:nostack static public function BytesToByteArray(bytes:Bytes):ByteArray {
		//return bytes.getData();
		var byteArray:ByteArray = new ByteArray();
		byteArray.endian = Endian.LITTLE_ENDIAN;
		for (n in 0 ... bytes.length) byteArray.writeByte(bytes.get(n));
		byteArray.position = 0;
		return byteArray;
	}
	
	@:nostack static public function ArrayToByteArray(array:Array<Int>):ByteArray {
		var byteArray:ByteArray = new ByteArray();
		byteArray.position = 0;
		for (n in 0 ... array.length) byteArray.writeByte(array[n]);
		return byteArray;
	}

	@:nostack static public function ArrayToBytes(array:Array<Int>):Bytes {
		var bytes:Bytes = Bytes.alloc(array.length);
		for (n in 0 ... bytes.length) bytes.set(n, array[n]);
		return bytes;
	}

	@:nostack static public function ByteArrayToBytes(byteArray:ByteArray):Bytes {
		var bytes:Bytes = Bytes.alloc(byteArray.length);
		byteArray.position = 0;
		for (n in 0 ... bytes.length) bytes.set(n, byteArray.readUnsignedByte());
		byteArray.position = 0;
		return bytes;
	}

}