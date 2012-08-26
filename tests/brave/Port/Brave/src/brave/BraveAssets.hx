package brave;
import brave.cgdb.CgDb;
import brave.cgdb.CgDbEntry;
import brave.formats.BraveImage;
import brave.formats.Decrypt;
import brave.sound.SoundPack;
import haxe.io.Bytes;
import nme.Assets;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.PixelSnapping;
import nme.media.Sound;
import nme.utils.ByteArray;
import nme.utils.Endian;
import sys.io.File;

/**
 * ...
 * @author 
 */

class BraveAssets 
{
	static var voicePack:SoundPack;
	static var soundPack:SoundPack;
	static var cgDb:CgDb;

	public function new() 
	{
		
	}
	
	static public function getCgDbEntry(name:String):CgDbEntry {
		if (cgDb == null) {
			cgDb = new CgDb(Decrypt.decryptDataWithKey(getBytes("cgdb.dat"), Decrypt.key23));
		}
		return cgDb.get(name);
	}
	
	static public function getBitmap(name:String):Bitmap {
		return new Bitmap(getBitmapData(name), PixelSnapping.AUTO, true);
	}

	static public function getBitmapData(name:String):BitmapData {
		var braveImage:BraveImage = new BraveImage();
		braveImage.load(BraveAssets.getBytes(Std.format("parts/${name}.CRP")));
		return braveImage.bitmapData;
	}

	static public function getSound(name:String):Sound {
		if (soundPack == null) {
			soundPack = new SoundPack(2, File.read(getBasePath() + "/sound.pck"));
		}
		return soundPack.getSound(name);
	}

	static public function getVoice(name:String):Sound {
		if (voicePack == null) {
			voicePack = new SoundPack(1, File.read(getBasePath() + "/voice/voice.pck"));
		}
		return voicePack.getSound(name);
	}

	static private function getBasePath():String
	{
		return "C:/juegos/brave_s";
	}

	static public function getBytes(name:String):ByteArray
	{
		//return Assets.getBytes("assets/" + name);
		var bytes:Bytes = File.getBytes(getBasePath() + "/" + name);
		var byteArray:ByteArray = new ByteArray();
		byteArray.endian = Endian.LITTLE_ENDIAN;
		for (n in 0 ... bytes.length) byteArray.writeByte(bytes.get(n));
		byteArray.position = 0;
		return byteArray;
	}
}