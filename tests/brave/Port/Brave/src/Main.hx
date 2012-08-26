package ;

import brave.BraveAssets;
import brave.formats.BraveImage;
import brave.sound.SoundPack;
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

	private function init(e) 
	{
		resize(e);

#if flash
		Log.setColor(0xFF0000);
#end

		//var script:Script = new Script();
		//script.setScriptWithName("op");
		//script.execute();
		
		/*
		var soundPack:SoundPack = new SoundPack(2, File.read("assets/sound.pck"));
		var voicePack:SoundPack = new SoundPack(1, File.read("assets/voice/voice.pck"));
		voicePack.getSound("x001001h").play(0, 0, new SoundTransform(0.2));
		*/
		
		//soundPack.getSound("a5_01001").play();
		
		//var morphedSound:Sound = new Sound();
		//morphedSound.addEventListener(SampleDataEvent.SAMPLE_DATA, playSound);
		//morphedSound.play();

		//addChild(BraveAssets.getBitmap("X_ALIC11"));
		
		Log.trace(BraveAssets.getCgDbEntry("A_DODR01"));
		
		//BraveAssets.getVoice("x001001h").play();
		
		//Decrypt.decryptDataWithKey(output, Decrypt.key23);
		// entry point
	}
	
	static public function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
		stage.align = nme.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new Main());
	}
	
}
