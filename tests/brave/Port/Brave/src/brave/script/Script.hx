package brave.script;
import brave.BraveAssets;
import brave.formats.Decrypt;
import brave.GameState;
import haxe.Log;
import haxe.rtti.Meta;
import nme.Assets;
import nme.errors.Error;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author 
 */

class Script 
{
	public var data:ByteArray;
	
	private function new() 
	{
	}

	static public function getScriptWithNameAsync(name:String, done:Script -> Void):Void {
		BraveAssets.getBytesAsync(Std.format("scenario/${name}.dat"), function(bytes:ByteArray) {
			done(getScriptWithByteArray(Decrypt.decryptDataWithKey(bytes, Decrypt.key23)));
		});
	}

	static public function getScriptWithByteArray(data:ByteArray):Script {
		var script:Script = new Script();
		script.data = data;
		script.data.endian = Endian.LITTLE_ENDIAN;
		script.data.position = 8;
		return script;
	}
}