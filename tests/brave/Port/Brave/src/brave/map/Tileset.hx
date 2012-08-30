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
	}
	
	public function loadDataAsync(done:Void -> Void):Void {
		if ((partId >= 0) && (name != "")) {
			BraveAssets.getBitmapDataAsync(name, function(bitmapData:BitmapData) {
				this.bitmapData = bitmapData;
				BraveAssets.getCgDbEntryAsync(name, function(cgDbEntry:CgDbEntry) {
					this.cgDbEntry = cgDbEntry;
					done();
				});
			});
		} else {
			done();
		}
	}
}