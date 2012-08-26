package brave;
import nme.utils.ByteArray;

/**
 * ...
 * @author 
 */

class ByteArrayUtils 
{
	static public function readStringz(data:ByteArray):String {
		var v:Int;
		var str:String = "";
		while ((v = data.readByte()) != 0) {
			str += String.fromCharCode(v);
		}
		return str;
	}

}