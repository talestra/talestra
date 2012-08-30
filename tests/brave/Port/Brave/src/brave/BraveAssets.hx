package brave;
import brave.cgdb.CgDb;
import brave.cgdb.CgDbEntry;
import brave.formats.BraveImage;
import brave.formats.Decrypt;
import brave.sound.SoundPack;
import brave.BraveLog;
import haxe.io.Bytes;
import nme.Assets;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.PixelSnapping;
import nme.errors.Error;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.media.Sound;
import nme.net.URLLoader;
import nme.net.URLLoaderDataFormat;
import nme.net.URLRequest;
import nme.utils.ByteArray;
import nme.utils.Endian;
import sys.FileSystem;
import nme.filesystem.File;

#if cpp
import sys.io.FileInput;
#end

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
	
	static public function getCgDbEntryAsync(name:String, done:CgDbEntry -> Void):Void {
		if (cgDb == null) {
			BraveAssets.getBytesAsync("cgdb.dat", function(data:ByteArray) {
				cgDb = new CgDb(Decrypt.decryptDataWithKey(data, Decrypt.key23));
				done(cgDb.get(name));
			});
		} else {
			done(cgDb.get(name));
		}
	}
	
	static public function getBitmapAsync(name:String, done:Bitmap -> Void):Void {
		BraveAssets.getBitmapDataAsync(name, function(bitmapData:BitmapData) {
			done(new Bitmap(bitmapData, PixelSnapping.AUTO, true));
		});
	}

	@:nostack static public function getBitmapDataWithAlphaCombinedAsync(name:String, done:BitmapData -> Void):Void {
		BraveAssets.getBitmapDataAsync(name, function(mixed:BitmapData) {
			var width:Int = mixed.width;
			var hwidth:Int = Std.int(width / 2);
			var height:Int = mixed.height;
			var out:BitmapData = new BitmapData(hwidth, height, true);
			var color:ByteArray = mixed.getPixels(new Rectangle(0, 0, hwidth, height));
			var alpha:ByteArray = mixed.getPixels(new Rectangle(hwidth, 0, hwidth, height));
			
			color.position = 0;
			alpha.position = 0;
			
			for (n in 0 ... Std.int(color.length / 4)) {
				color[n * 4 + 0] = alpha[n * 4 +1];
			}
			
			out.setPixels(out.rect, color);
			
			done(out);
		});
	}

	/*
	static public function getBitmapData(name:String):BitmapData {
		var braveImage:BraveImage = new BraveImage();
		braveImage.load(BraveAssets.getBytes(Std.format("parts/${name}.CRP")));
		return braveImage.bitmapData;
	}
	*/

	static public function getBitmapDataAsync(name:String, done:BitmapData -> Void):Void {
		name = name.toUpperCase();
		
		BraveAssets.getBytesAsync(Std.format("parts/${name}.CRP"), function(bytes:ByteArray) {
			var braveImage:BraveImage = new BraveImage();
			braveImage.load(bytes);
			done(braveImage.bitmapData);
		});
	}
	
	static private function getDummySound():Sound {
		var sound:Sound = new Sound();
		var byteArray:ByteArray = new ByteArray();
		byteArray.writeFloat(0);
		byteArray.writeFloat(0);
		byteArray.position = 0;
		sound.loadPCMFromByteArray(byteArray, 1);
		return sound;
	}

	static public function getSoundAsync(name:String, done:Sound -> Void):Void {
		#if !cpp
			done(getDummySound());
		#else
			if (soundPack == null) {
				soundPack = new SoundPack(2, getStream("sound.pck"));
			}
			done(soundPack.getSound(name));
		#end
	}

	static public function getVoiceAsync(name:String, done:Sound -> Void):Void {
		#if !cpp
			/*
			BraveAssets.getBytesAsync(Std.format("voice/$name.wav"), function(voiceArray:ByteArray):Void {
				var sound:Sound = new Sound();
				sound.loadCompressedDataFromByteArray(voiceArray, voiceArray.length);
				done(sound);
			});
			*/
			done(getDummySound());
		#else
			if (voicePack == null) {
				voicePack = new SoundPack(1, getStream("voice/voice.pck"));
			}
			done(voicePack.getSound(name));
		#end
	}
	
	static public function getMusicAsync(name:String, done:Sound -> Void):Void {
		#if !cpp
			done(getDummySound());
		#else
			BraveAssets.getBytesAsync("midi/" + name + ".mid", function(bytes:ByteArray) {
				var sound:Sound = new Sound();
				//sound.loadPCMFromByteArray(
				try {
					sound.loadCompressedDataFromByteArray(bytes, bytes.length, true);
				} catch (e:Error) {
					BraveLog.trace(e);
				}
				done(sound);
			});
		#end
	}

	#if !cpp
		static public function getBytesAsync(name:String, done:ByteArray -> Void):Void {
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, function(e) {
				done(loader.data);
			});
			loader.addEventListener("ioError", function(e) {
				throw(new Error(Std.format("Can't load asset '$name' : IO Error")));
			});
			loader.addEventListener("securityError", function(e) {
				throw(new Error(Std.format("Can't load asset '$name' : Security Error")));
			});
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(new URLRequest("assets/" + name));
			/*
			var bytes:ByteArray = Assets.getBytes("assets/" + name);
			if (bytes == null) throw(new Error(Std.format("Can't load asset '$name'")));
			done(bytes);
			*/
		}
	#else
		static private var cachedBasePath:String = null;
	
		static private function getBasePath():String
		{
			if (cachedBasePath == null) {
				for (tryPath in [File.applicationDirectory.nativePath + "/assets", "assets", "../assets", "../../assets", "../../../assets", "../../../../assets"]) {
					if (FileSystem.isDirectory(tryPath)) {
						cachedBasePath = FileSystem.fullPath(tryPath);
						break;
					}
				}
			}
			
			if (cachedBasePath != null) {
				return cachedBasePath;
			} else {
				
				BraveLog.trace(FileSystem.fullPath('.'));
				BraveLog.trace(File.applicationDirectory.nativePath);
				BraveLog.trace(File.applicationStorageDirectory.nativePath);
				BraveLog.trace(File.desktopDirectory.nativePath);
				BraveLog.trace(File.documentsDirectory.nativePath);
				BraveLog.trace(File.userDirectory.nativePath);
				throw(new Error("Can't find assets path"));
			}
		}
		
		static private function getFinalFileName(name:String):String {
			var filePath:String = getBasePath() + "/" + name;
			var filePath2:String = getBasePath() + ("/assets_" + StringTools.replace(StringTools.replace(name, '/', '_'), '.', '_')).toLowerCase();
			if (!sys.FileSystem.exists(filePath)) filePath = filePath2;
			return filePath;		
		}

		static public function getBytesAsync(name:String, done:ByteArray -> Void):Void {
			var bytes:ByteArray = ByteUtils.BytesToByteArray(sys.io.File.getBytes(getFinalFileName(name)));
			done(bytes);
		}

		static private function getStream(name:String):FileInput {
			return sys.io.File.read(getFinalFileName(name));
		}
	#end
}
