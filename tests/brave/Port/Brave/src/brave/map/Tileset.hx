package brave.map;
import brave.BraveAssets;
import brave.cgdb.CgDbEntry;
import nme.display.BitmapData;

/**
 * ...
 * @author 
 */

class Tileset 
{
	public var partId:Int;
	public var name:String;
	public var bitmapData:BitmapData;
	public var cgDbEntry:CgDbEntry;

	public function new(partId:Int, name:String)
	{
		this.partId = partId;
		this.name = name;
		if ((partId >= 0) && (name != "")) {
			this.bitmapData = BraveAssets.getBitmapData(name);
			this.cgDbEntry = BraveAssets.getCgDbEntry(name);
		}
	}
	
}