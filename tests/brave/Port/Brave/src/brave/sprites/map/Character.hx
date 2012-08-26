package brave.sprites.map;
import brave.BraveAssets;
import brave.GraphicUtils;
import brave.map.Map;
import brave.map.Tileset;
import haxe.Timer;
import nme.display.Sprite;

/**
 * ...
 * @author 
 */

class Character 
{
	public var id:Int;
	public var tileset:Tileset;
	public var x:Int;
	public var y:Int;
	public var sprite:Sprite;
	public var direction:Int;
	public var frame:Int;
	var frameNums:Array<Int>;
	
	public function new(id:Int, imageName:String, x:Int, y:Int) 
	{
		this.id = id;
		this.tileset = new Tileset(1, imageName);
		this.x = x;
		this.y = y;
		this.direction = 0;
		this.frame = 0;
		this.sprite = new Sprite();
		this.frameNums = [0, 1, 0, 2];
		
		move();
	}
	
	private function move():Void {
		this.y += 2;
		frame++;
		Timer.delay(move, 30);
	}
	
	public function updateSprite():Void {
		var tileHeight:Int = tileset.cgDbEntry.tileHeight;
		var tileWidth:Int = tileset.cgDbEntry.tileWidth;
		var tileY:Int = this.direction % 4;
		var tileX:Int = frameNums[Std.int(this.frame / 4) % frameNums.length];
		sprite.graphics.clear();
		GraphicUtils.drawBitmapSlice(sprite.graphics, tileset.bitmapData, 0, -tileHeight, tileX * tileWidth, tileY * tileHeight, tileWidth, tileHeight); 
	}
}