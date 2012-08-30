package brave.script;
import haxe.Log;
import nme.errors.Error;

/**
 * ...
 * @author 
 */

class Instruction {
	public var opcode:Opcode;
	public var parameters:Array<Dynamic>;
	public var async:Bool;
	
	public function new(opcode:Opcode, parameters:Array<Dynamic>, async:Bool) {
		this.opcode = opcode;
		this.parameters = parameters;
		this.async = async;
	}
	
	public function call(object:Dynamic):Dynamic {
		if (opcode.unimplemented) {
			BraveLog.trace(Std.format("Unimplemented: $this"));
		} else {
			BraveLog.trace(Std.format("Executing... $this"));
		}
		return Reflect.callMethod(object, Reflect.field(object, opcode.methodName), parameters);
	}
	
	public function toString():String {
		return Std.format("$opcode ${parameters.join(', ')}");
	}
}