package brave;
import brave.script.Script;
import brave.script.ScriptThread;
import brave.script.Variable;
import brave.sprites.GameSprite;
import haxe.Log;
import haxe.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.errors.Error;

/**
 * ...
 * @author 
 */

class GameState 
{
	public var variables:Array<Variable>;
	public var rootClip:GameSprite;

	public function new(rootClip:GameSprite) 
	{
		this.rootClip = rootClip;
		
		this.variables = new Array<Variable>();
		for (n in 0 ... 10000) this.variables.push(new Variable());
	}
	
	public function spawnThreadWithScript(script:Script):ScriptThread {
		var scriptThread:ScriptThread = new ScriptThread(this);
		scriptThread.setScript(script);
		return scriptThread;
	}
	
	public function setBackgroundColor(color:Int):Void {
		SpriteUtils.extractSpriteChilds(rootClip.backgroundBack);
		rootClip.backgroundBack.addChild(SpriteUtils.createSolidRect(color));
	}

	public function setBackgroundImage(imageName:String):Void {
		SpriteUtils.extractSpriteChilds(rootClip.backgroundBack);
		var image:Bitmap = BraveAssets.getBitmap(imageName);
		if (image != null) {
			rootClip.backgroundBack.addChild(image);
		} else {
			throw(new Error(Std.format("Can't load image '$imageName'")));
		}
	}
	
	public function transition(done:Void -> Void, type:Int):Void {
		//rootClip.backgroundFront.alpha
		var time:Float = 0.5;
		
		Animation.animate(function() {
			rootClip.backgroundFront.alpha = 1;
			SpriteUtils.swapSpriteChildren(rootClip.backgroundFront, rootClip.backgroundBack);
			done();
		}, time, rootClip.backgroundFront, { alpha : 0 }, Animation.Sin);
	}
}