package brave.sound;
import haxe.io.Bytes;
import nme.media.Sound;

/**
 * ...
 * @author 
 */

class SoundEntry 
{
	public var soundPack:SoundPack;
	public var name:String;
	public var offset:Int;
	public var length:Int;
	public var bytes:Bytes;

	public function new(soundPack:SoundPack, name:String, offset:Int, length:Int) 
	{
		this.soundPack = soundPack;
		this.name = name;
		this.offset = offset;
		this.length = length;
	}
	
	public function getSound():Sound {
		if (bytes == null) {
			soundPack.file.seek(this.offset, sys.io.FileSeek.SeekBegin);
			bytes = soundPack.file.read(this.length);
		}
		var soundInstance:SoundInstance = new SoundInstance(this);
		return soundInstance.getSound();
	}
}