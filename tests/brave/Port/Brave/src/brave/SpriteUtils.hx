package brave;
import haxe.Log;
import nme.display.DisplayObject;
import nme.display.Graphics;
import nme.display.Sprite;

/**
 * ...
 * @author 
 */

class SpriteUtils 
{
	static public function center<T : (DisplayObject)>(sprite:T, cx:Float, cy:Float):T {
		sprite.x = -sprite.width * cx;
		sprite.y = -sprite.height * cy;
		return sprite;
	}
	
	static public function extractSpriteChilds(container:Sprite):Array<DisplayObject> {
		var children:Array<DisplayObject> = new Array<DisplayObject>();
		while (container.numChildren > 0) {
			var child:DisplayObject = container.getChildAt(0);
			container.removeChildAt(0);
			children.unshift(child);
		}
		return children;
	}
	
	static public function insertSpriteChilds(container:Sprite, children:Array<DisplayObject>):Void {
		for (n in 0 ... children.length) {
			container.addChild(children[n]);
		}
	}
	
	static public function dumpSpriteChildren(name:String, sprite:Sprite):Void {
		for (n in 0 ... sprite.numChildren) BraveLog.trace(name + ":" + sprite.getChildAt(n));
	}

	static public function swapSpriteChildren(sprite1:Sprite, sprite2:Sprite):Void {
		//BraveLog.trace("-------------------------");
		//dumpSpriteChildren("sprite1", sprite1);
		//dumpSpriteChildren("sprite2", sprite2);
		//BraveLog.trace("->");
		var sprite1Children:Array<DisplayObject> = extractSpriteChilds(sprite1);
		var sprite2Children:Array<DisplayObject> = extractSpriteChilds(sprite2);
		insertSpriteChilds(sprite2, sprite1Children);
		insertSpriteChilds(sprite1, sprite2Children);
		//dumpSpriteChildren("sprite1", sprite1);
		//dumpSpriteChildren("sprite2", sprite2);
		//BraveLog.trace("-------------------------");
	}
	
	static public function createSolidRect(color:Int = 0x000000, alpha:Float = 1, width:Int = 640, height:Int = 480):Sprite {
		var sprite:Sprite = new Sprite();
		var graphics:Graphics = sprite.graphics;
		graphics.beginFill(color, alpha);
		graphics.drawRect(0, 0, width, height);
		graphics.endFill();
		return sprite;
	}
}