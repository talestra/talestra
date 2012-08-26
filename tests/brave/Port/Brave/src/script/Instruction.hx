package script;
import haxe.Log;
import nme.errors.Error;

/**
 * ...
 * @author 
 */

class Instruction {
	public var opcode:Opcode;
	public var parameters:Array<Dynamic>;
	
	public function new(opcode:Opcode, parameters:Array<Dynamic>) {
		this.opcode = opcode;
		this.parameters = parameters;
	}
	
	public function call(object:Dynamic):Dynamic {
		//Log.trace(Std.format("$opcode ${parameters.join(', ')}"));
		return Reflect.callMethod(object, Reflect.field(object, opcode.methodName), parameters);
	}
}