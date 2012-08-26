package ;

import brave.BraveAssets;
import brave.formats.BraveImage;
import brave.GameState;
import brave.map.Map;
import brave.script.Script;
import brave.script.ScriptThread;
import brave.sound.SoundPack;
import brave.sprites.GameSprite;
import brave.sprites.map.Character;
import brave.sprites.map.MapSprite;
import haxe.Timer;
import nme.events.SampleDataEvent;
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
#if !flash
import sys.io.File;
#end

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
		
		var woods:Map = Map.loadFromName("e_beac0");
		var mapSprite:MapSprite = new MapSprite();
		addChild(mapSprite);
		mapSprite.setMap(woods);
		/*
		mapSprite.moveCameraTo(500, 500, 2, function() {
			mapSprite.moveCameraTo(200, 2000, 2);
		});
		*/
		
		
		mapSprite.addCharacter(new Character(0, "C_RUDY", 970, 340));
		mapSprite.reorderEntities();
		mapSprite.enableMoveWithKeyboard();
		
		/*
		var gameState:GameState = new GameState(gameSprite);
		var scriptThread:ScriptThread = gameState.spawnThreadWithScript(Script.getScriptWithName("op"));
		scriptThread.execute();
		*/
		
	}

	
	static public function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
		stage.align = nme.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new Main());
	}
	
}
