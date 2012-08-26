package brave.map;
import brave.GraphicUtils;
import nme.display.Graphics;
import nme.geom.Matrix;

/**
 * ...
 * @author 
 */

class CellLayer 
{
	public var tileset:Tileset;
	public var x:Int;
	public var y:Int;

	public function new(tileset:Tileset, x:Int, y:Int) 
	{
		this.tileset = tileset;
		this.x = x;
		this.y = y;
	}
	
	public function drawTo(graphics:Graphics, x:Int, y:Int):Void {
		var w:Int = tileset.cgDbEntry.tileWidth;
		var h:Int = tileset.cgDbEntry.tileHeight;
		GraphicUtils.drawBitmapSlice(graphics, tileset.bitmapData, x, y - h, this.x, this.y, w, h);
		/*
		
		matrix.identity();
		matrix.translate(-this.x + (x), -this.y + (y - h));
		graphics.beginBitmapFill(tileset.bitmapData, matrix, false, true);
		//graphics.beginBitmapFill(tileset.bitmapData, matrix, true, false);
		graphics.drawRect(x, y - h, w, h);
		graphics.endFill();
		*/
	}
}