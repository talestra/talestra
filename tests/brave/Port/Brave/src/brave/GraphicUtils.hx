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
	
}