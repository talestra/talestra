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

	static public function getScriptWithName(name:String):Script {
		return getScriptWithByteArray(Decrypt.decryptDataWithKey(BraveAssets.getBytes(Std.format("scenario/${name}.dat")), Decrypt.key23));
	}

	static public function getScriptWithByteArray(data:ByteArray):Script {
		var script:Script = new Script();
		script.data = data;
		script.data.endian = Endian.LITTLE_ENDIAN;
		script.data.position = 8;
		return script;
	}
}