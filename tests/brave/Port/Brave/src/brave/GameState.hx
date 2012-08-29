package brave;
import brave.map.Map;
import brave.script.Script;
import brave.script.ScriptThread;
import brave.script.Variable;
import brave.sprites.GameSprite;
import brave.sprites.map.Character;
import haxe.Log;
import haxe.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.display.Stage;
import nme.errors.Error;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.geom.ColorTransform;
import nme.Lib;
import nme.media.SoundChannel;
import nme.utils.ByteArray;

/**
 * ...
 * @author 
 */

class GameState 
{
	public var variables:Array<Variable>;
	public var rootClip:GameSprite;
	public var musicChannel:SoundChannel;
	
	public function new(rootClip:GameSprite) 
	{
		this.rootClip = rootClip;
		
		this.variables = new Array<Variable>();
		for (n in 0 ... 10000) this.variables.push(new Variable(0));
		Lib.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Lib.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		keyPress = new IntHash<Void>();
	}
	
	static var keyPress:IntHash<Void>;
	//static var pressingControl:Bool = false;
	
	public function onKeyDown(e:KeyboardEvent):Void {
		//pressingControl = e.ctrlKey;
		keyPress.set(e.keyCode, null);
		//Log.trace(e.keyCode);
	}

	public function onKeyUp(e:KeyboardEvent):Void {
		//pressingControl = e.ctrlKey;
		keyPress.remove(e.keyCode);
	}

	public function spawnThreadWithScript(script:Script):ScriptThread {
		var scriptThread:ScriptThread = new ScriptThread(this);
		scriptThread.setScript(script);
		return scriptThread;
	}
	
	public function setMap(mapName:String):Void {
		rootClip.mapSprite.setMap(Map.loadFromName(mapName));
	}

	public function getAllCharacters():Iterator<Character> {
		if (rootClip == null) throw(new Error("rootClip is null"));
		if (rootClip.mapSprite == null) throw(new Error("rootClip.mapSprite is null"));
		if (rootClip.mapSprite.characters == null) throw(new Error("rootClip.mapSprite.characters is null"));
		return rootClip.mapSprite.characters.iterator();
	}

	public function getCharacter(charaId:Int):Character {
		var chara:Character = rootClip.mapSprite.characters.get(charaId);
		if (chara == null) throw(new Error(Std.format("Can't get character with id=${charaId}")));
		return chara;
	}

	public function charaSpawn(charaId:Int, face:Int, unk:Int, x:Int, y:Int, direction:Int):Void {
		var partName:String = switch (charaId) {
			case 0: "C_RUDY";
			case 1: "C_SCHELL";
			case 3: "C_ALICIA";
			default: "C_GOBL01";
		};
		rootClip.mapSprite.addCharacter(new Character(rootClip.mapSprite, charaId, partName, x * 40, y * 40, direction));
	}
	
	static public function waitClickOrKeyPress(done:Void -> Void):Void {
		if (keyPress.exists(17)) {
			Timer.delay(function() {
				done();
			}, 1);
			return;
		}
		var onClick = null;
		onClick = function(e) {
			Lib.stage.removeEventListener(MouseEvent.CLICK, onClick);
			Lib.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onClick);

			Timer.delay(function() {
				done();
			}, 1);
		};
		Lib.stage.addEventListener(MouseEvent.CLICK, onClick);
		Lib.stage.addEventListener(KeyboardEvent.KEY_DOWN, onClick);
	}
	
	public function setBackgroundColor(color:Int):Void {
		SpriteUtils.extractSpriteChilds(rootClip.backgroundBack);
		rootClip.backgroundBack.addChild(SpriteUtils.createSolidRect(color));
	}

	public function setBackgroundEffect(effectType:Int):Void {
		var out:BitmapData = new BitmapData(640, 480);
		out.draw(rootClip.backgroundBack);
		//rootClip.backgroundBack
		var pixels:ByteArray = out.getPixels(out.rect);
		
		pixels.position = 0;
		
		for (n in 0 ... Std.int(pixels.length / 4)) {
			var offset:Int = n * 4;
			var grey:Int = Std.int((pixels[offset + 1] + pixels[offset + 2] + pixels[offset + 3]) / (3));
			
			pixels[offset + 0] = 0xFF;
			pixels[offset + 1] = Std.int(grey * 1.0);
			pixels[offset + 2] = Std.int(grey * 0.8);
			pixels[offset + 3] = Std.int(grey * 0.6);
		}
		
		out.setPixels(out.rect, pixels);
		
		SpriteUtils.extractSpriteChilds(rootClip.backgroundBack);
		rootClip.backgroundBack.addChild(new Bitmap(out));
	}

	public function setBackgroundImage(imageName:String):Void {
		rootClip.background.alpha = 1;
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
		
		//rootClip.backgroundBack.transform.colorTransform = new ColorTransform(1, 0.6, 0.3, 1.0, 0, 0, 0, 0);
		
		Animation.animate(function() {
			rootClip.backgroundFront.alpha = 1;
			SpriteUtils.swapSpriteChildren(rootClip.backgroundFront, rootClip.backgroundBack);
			done();
		}, time, rootClip.backgroundFront, { alpha : 0 }, Animation.Sin);
	}
	
	public function fadeToMap(done:Void -> Void, time:Int):Void {
		var time:Float = 0.5;
		
		Animation.animate(function() {
			done();
		}, time, rootClip.background, { alpha : 0 }, Animation.Sin);
	}
}