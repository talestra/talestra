package formats.sound;
import haxe.io.BytesInput;
import haxe.Log;
import nme.events.Event;
import nme.events.SampleDataEvent;
import nme.media.Sound;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author 
 */

class SoundInstance 
{
	var soundEntry:SoundEntry;
	var bytesInput:BytesInput;
	var offset:Int;
	var fromChannels:Int;
	var sound:Sound;
	var completed:Bool = false;
	
	static public inline var FromRate:Int = 11025;
	static public inline var ToRate:Int = 44100;
	static public inline var GeneratedSamples:Int = Std.int(ToRate / FromRate);
	
	static public inline var toChannels:Int = 2;

	public function new(soundEntry:SoundEntry) 
	{
		this.soundEntry = soundEntry;
		this.bytesInput = new BytesInput(soundEntry.bytes);
		this.bytesInput.bigEndian = false;
		this.offset = 0;
		this.fromChannels = soundEntry.soundPack.numberOfChannels;

		this.lastSamples = new Array<Float>();
		this.lastSamples.push(0);
		this.lastSamples.push(0);
		this.currentSamples = new Array<Float>();
		this.currentSamples.push(0);
		this.currentSamples.push(0);
	}
	
	public function getSound():Sound {
		//Log.trace("getSound");
		sound = new Sound();
		loadData();
		return sound;
	}
	
	/*
	private function loadData():Void  {
		var wav:ByteArray = new ByteArray();
		wav.endian = Endian.LITTLE_ENDIAN;
		
		var Bytes = soundEntry.bytes;
		var AudioFormat:Int = 1;
		var NumChannels:Int = fromChannels;
		var SampleRate:Int = 11025;
		var BitsPerSample:Int = 16;
		var ByteRate:Int = Std.int(SampleRate * NumChannels * BitsPerSample / 8);
		var BlockAlign:Int = Std.int(NumChannels * BitsPerSample / 8);
		var NumSamples:Int = Std.int(Bytes.length / BlockAlign);
		
		//sound.loadPCMFromByteArray(soundEntry.bytes, soundEntry.bytes.length / 2 / fromChannels, "short", (fromChannels == 2) ? true : false, FromRate);
		
		wav.writeUTFBytes("RIFF");
		wav.writeInt(36 + Bytes.length);
		wav.writeUTFBytes("WAVE");
		wav.writeUTFBytes("fmt ");
		wav.writeInt(16); // Subchunk1Size
		wav.writeShort((AudioFormat)); // AudioFormat
		wav.writeShort((NumChannels));
		wav.writeInt((SampleRate));
		wav.writeInt((ByteRate));
		wav.writeShort((BlockAlign));
		wav.writeShort((BitsPerSample));
		wav.writeUTFBytes("data");
		wav.writeInt((Bytes.length));
		wav.writeBytes(Bytes, 0, Bytes.length);
		
		wav.position = 0;
		sound.loadCompressedDataFromByteArray(wav, wav.length);
	}
	*/
	
	private function loadData():Void  {
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, playSound);
	}
	
	private function hasMoreSamples():Bool {
		return offset < soundEntry.bytes.length;
	}
	
	private function readSample():Int {
		offset += 2;
		return bytesInput.readInt16();
	}
	
	static private inline function interpolate(a:Float, b:Float, step:Float):Float {
		return a * (1 - step) + b * step;
	}
	
	var currentSamples:Array<Float>;
	var lastSamples:Array<Float>;
	
	private function playSound(soundOutput:SampleDataEvent):Void
	{
		//Log.trace("playSound");
		for (n in 0 ... Std.int(8192 / GeneratedSamples))
		{
			if (!hasMoreSamples()) {
				if (!completed) {
					completed = true;
					sound.dispatchEvent(new Event(Event.COMPLETE));
				}
				for (step in 1 ... GeneratedSamples + 1) {
					for (channel in 0 ... toChannels) {
						soundOutput.data.writeFloat(0);
					}
				}
			} else {
				for (channel in 0 ... fromChannels) {
					currentSamples[channel] = readSample() / 0x7FFF;
				}

				for (step in 1 ... GeneratedSamples + 1) {
					for (channel in 0 ... toChannels) {
						soundOutput.data.writeFloat(
							interpolate(lastSamples[channel % fromChannels], currentSamples[channel % fromChannels], step / GeneratedSamples)
						);
					}
				}
				
				for (channel in 0 ... fromChannels) {
					lastSamples[channel] = currentSamples[channel];
				}
			}
		}
		//soundOutput.
	}
}