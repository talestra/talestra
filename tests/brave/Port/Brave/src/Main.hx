package ;

import brave.BraveAssets;
import brave.formats.BraveImage;
import brave.GameInput;
import brave.GameState;
import brave.map.Map;
import brave.script.Script;
import brave.script.ScriptReader;
import brave.script.ScriptThread;
import brave.sound.SoundPack;
import brave.sprites.GameSprite;
import brave.sprites.map.Character;
import brave.sprites.map.MapSprite;
import brave.StringEx;
import haxe.Timer;
import nme.media.Sound;
import nme.media.SoundChannel;
import nme.media.SoundLoaderContext;
import haxe.Log;
import nme.Assets;
import nme.display.Bitmap;
import nme.display.PixelSnapping;
import nme.display.Sprite;
import nme.events.Event;
import nme.Lib;
import nme.media.SoundTransform;

/**
 * ...
 * @author soywiz
 */

class Main extends Sprite 
{
	
	public function new() 
	{
		super();
		#if iphone
		Lib.current.stage.addEventListener(Event.RESIZE, init);
		#else
		addEventListener(Event.ADDED_TO_STAGE, init);
		Lib.current.stage.addEventListener(Event.RESIZE, resize);
		#end
	}

	private function resize(e) 
	{
		var propX = stage.stageWidth / 640;
		var propY = stage.stageHeight / 480;
		var usedWidth, usedHeight;
		
		if (propX < propY) {
			scaleY = scaleX = propX;
		} else {
			scaleY = scaleX = propY;
		}
		
		usedWidth = 640 * scaleX;
		usedHeight = 480 * scaleY;

		this.x = Std.int((stage.stageWidth - usedWidth) / 2);
		this.y = Std.int((stage.stageHeight - usedHeight) / 2);
	}
	
	var gameSprite:GameSprite;
	
	private function init(e) 
	{
		resize(e);

#if flash
		Log.setColor(0xFF0000);
#end

		addChild(gameSprite = new GameSprite());
		
		GameInput.init();
		
		/*
		var faceId = 57;
		BraveLog.trace(StringEx.sprintf("Z_%02d_%02d", [Std.int(faceId / 100), Std.int(faceId % 100)]));
		*/
		
		//new ScriptReader(Script.getScriptWithName("op")).readAllInstructions();
		
		if (false) {
			Map.loadFromNameAsync("a_wood0", function(woods:Map):Void {
				var mapSprite:MapSprite = new MapSprite();
				addChild(mapSprite);
				mapSprite.setMap(woods);
				var character:Character = new Character(mapSprite, 0, "C_RUDY", 20 * 40, 71 * 40);
				character.loadImageAsync(function() {
					mapSprite.addCharacter(character);
				});
			});
		} else {
			var startScriptName:String = "start";
			//var startScriptName:String = "op";
			//var startScriptName:String = "op_2";
			//var startScriptName:String = "a_bar";
			//var startScriptName:String = "end_3";
			//var startScriptName:String = "e_m20";
			//var startScriptName:String = "e_k99";
			//var startScriptName:String = "e_m99";
			var gameState:GameState = new GameState(gameSprite);
			Script.getScriptWithNameAsync(startScriptName, function(script:Script) {
				var scriptThread:ScriptThread = gameState.spawnThreadWithScript(script);
				scriptThread.execute();
			});
		}
	}

	
	static public function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
		stage.align = nme.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new Main());
	}
	
}
