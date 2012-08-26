package ;

import formats.BraveImage;
import formats.Decrypt;
import formats.sound.SoundPack;
import nme.events.SampleDataEvent;
import nme.media.Sound;
import nme.media.SoundLoaderContext;
import script.Script;
import haxe.Log;
import nme.Assets;
import nme.display.Bitmap;
import nme.display.PixelSnapping;
import nme.display.Sprite;
import nme.events.Event;
import nme.Lib;
import src.formats.LZ;
import src.formats.LZ;
import sys.io.File;

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
		#end
	}

	private function init(e) 
	{
		scaleX = stage.stageWidth / 640;
		scaleY = stage.stageHeight / 480;

#if flash
		Log.setColor(0xFF0000);
#end

		//var script:Script = new Script();
		//script.setScriptWithName("op");
		//script.execute();
		
		var soundPack:SoundPack = new SoundPack(2, File.read("assets/sound.pck"));
		var voicePack:SoundPack = new SoundPack(1, File.read("assets/voice/voice.pck"));
		voicePack.getSound("x001001h").play();
		soundPack.getSound("a5_01001").play();
		
		//var morphedSound:Sound = new Sound();
		//morphedSound.addEventListener(SampleDataEvent.SAMPLE_DATA, playSound);
		//morphedSound.play();

		var braveImage:BraveImage = new BraveImage();
		braveImage.load(Assets.getBytes("assets/parts/C_001.CRP"));
		
		var bitmap:Bitmap = new Bitmap(braveImage.bitmapData, PixelSnapping.AUTO, true);
		addChild(bitmap);
		
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
