package brave.cgdb;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author 
 */

class CgDb 
{
	private var entries:Hash<CgDbEntry>;

	public function new(?data:ByteArray) 
	{
		if (data != null) load(data);
	}
	
	public function get(name:String):CgDbEntry {
		return entries.get(name.toLowerCase());
	}
	
	private function readEntry(data:ByteArray):CgDbEntry {
		data.endian = Endian.LITTLE_ENDIAN;
		var startPosition:Int = data.position;
		var type:Int = data.readInt();
		data.readByte();
		//var name:String = data.readMultiByte(11, "shift-jis");
		var name:String = data.readUTFBytes(11);
		var imageId:Int = data.readInt();
		var tileWidth:Int = data.readInt();
		var tileHeight:Int = data.readInt();
		data.position = startPosition + 0x28;
		name = StringTools.replace(name, String.fromCharCode(0), "");
		return new CgDbEntry(type, name, imageId, tileWidth, tileHeight);
	}
	
	public function load(data:ByteArray):Void {
		entries = new Hash<CgDbEntry>();
		data.position = 8;
		while (data.bytesAvailable > 0) {
			var entry:CgDbEntry = readEntry(data);
			entries.set(entry.name.toLowerCase(), entry);
		}
	}
}