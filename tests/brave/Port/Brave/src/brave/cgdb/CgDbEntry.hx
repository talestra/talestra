package brave.cgdb;

/**
 * ...
 * @author 
 */

class CgDbEntry 
{
	public var type:Int;
	public var name:String;
	public var imageId:Int;
	public var tileWidth:Int;
	public var tileHeight:Int;

	public function new(type:Int, name:String, imageId:Int, tileWidth:Int, tileHeight:Int) 
	{
		this.type = type;
		this.name = name;
		this.imageId = imageId;
		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;
	}
	
	public function toString():String {
		return Std.format("CgDbEntry(Type = ${type}, Name = '${name}', ImageId = ${imageId}, TileSize = ${tileWidth}x${tileHeight})");
	}
}