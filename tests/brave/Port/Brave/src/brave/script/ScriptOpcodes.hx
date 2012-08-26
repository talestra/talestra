package brave.script;
import haxe.rtti.Meta;
import nme.errors.Error;

/**
 * ...
 * @author 
 */

class ScriptOpcodes 
{
	static private var opcodesById:IntHash<Opcode>;
	
	static private function initializeOpcodesById() {
		if (opcodesById == null) {
			var metas = Meta.getFields(ScriptInstructions);
			//Log.trace(metas.JUMP_IF);
			
			opcodesById = new IntHash<Opcode>();
			
			for (key in Reflect.fields(metas)) {
				var metas:Dynamic = Reflect.getProperty(metas, key);
				var opcodeAttribute:Dynamic = metas.Opcode;
				var unimplemented:Bool = Reflect.hasField(metas, "Unimplemented");
				
				//Log.trace(unimplemented);
				if (opcodeAttribute != null) {
					var id = opcodeAttribute[0];
					var format = opcodeAttribute[Std.int(opcodeAttribute.length - 1)];
					addOpcode(key, id, format, unimplemented);
				}
			}
		}
	}

	static private function addOpcode(methodName:String, opcodeId:Int, format:String, unimplemented:Bool) {
		//Reflect.callMethod(this, 
		//Log.trace(Std.format("$methodName, $opcodeId, $format"));
		opcodesById.set(opcodeId, new Opcode(methodName, opcodeId, format, unimplemented));
	}

	static public function getOpcodeWithId(id:Int) 
	{
		initializeOpcodesById();
		var opcode = opcodesById.get(id);
		if (opcode == null) throw(new Error(Std.format("Unknown opcode ${id}")));
		return opcode;
	}
	
}