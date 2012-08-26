package brave.sound;
//import haxe.io.Input;
import haxe.Log;
import nme.errors.Error;
import nme.media.Sound;

typedef Input = sys.io.FileInput;

/**
 * ...
 * @author 
 */

class SoundPack 
{
	public var file:Input;
	private var startPosition:Int;
	private var entries:Hash<SoundEntry>;
	public var numberOfChannels:Int;

	public function new(numberOfChannels:Int = 1, ?file:Input)
	{
		this.entries = new Hash<SoundEntry>();
		this.numberOfChannels = numberOfChannels;
		if (file != null) load(file);
	}
	
	public function getSound(soundFile:String):Sound {
		var entry:SoundEntry = entries.get(soundFile);
		if (entry == null) throw(new Error(Std.format("Can't find sound '${soundFile}'")));
		return entry.getSound();
	}
	
	private function readEntry():SoundEntry {
		var name:String = file.readString(10);
		var length:Int = file.readUInt30();
		var position:Int = file.readUInt30() + startPosition;
		file.read(6);
		return new SoundEntry(this, name, position, length);
	}
	
	public function load(file:Input):Void {
		this.file = file;
		file.readInt32();
		var headerBlocks:Int = file.readUInt16();
		var entryCount:Int = file.readUInt16();
		file.read(headerBlocks * 20);
		file.readUInt16();
		
		startPosition = 4 + 2 + 2 + (headerBlocks * 20) + 2 + (entryCount * 24);
		
		for (n in 0 ... entryCount) {
			var entry:SoundEntry = readEntry();
			entries.set(entry.name, entry);
			//Log.trace(entry.name);
		}
	}
}