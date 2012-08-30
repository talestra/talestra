package brave;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Graphics;
import nme.geom.Matrix;

/**
 * ...
 * @author 
 */

class GraphicUtils 
{
	static private var matrix:Matrix = new Matrix();

	static public function drawBitmapSlice(graphics:Graphics, bitmap:BitmapData, x:Int, y:Int, srcX:Int, srcY:Int, w:Int, h:Int):Void {
		matrix.identity();
		matrix.translate(x - srcX, y - srcY);
		graphics.beginBitmapFill(bitmap, matrix, false, true);
		{
			graphics.drawRect(x, y, w, h);
		}
		graphics.endFill();
	}

	static public function drawSolidFilledRectWithBounds(graphics:Graphics, x0:Float, y0:Float, x1:Float, y1:Float, rgb:Int = 0x000000, alpha:Float = 1.0):Void {
		var x = x0;
		var y = y0;
		var w = x1 - x0;
		var h = y1 - y0;
		graphics.beginFill(rgb, alpha);
		graphics.drawRect(x, y, w, h);
		graphics.endFill();
	}
}