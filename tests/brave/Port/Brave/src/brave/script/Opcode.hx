package brave.script;

/**
 * ...
 * @author 
 */

class Opcode {
	public var methodName:String;
	public var opcodeId:Int;
	public var format:String;
	
	public function new(methodName:String, opcodeId:Int, format:String) {
		this.methodName = methodName;
		this.opcodeId = opcodeId;
		this.format = format;
	}
	
	public function toString():String {
		return Std.format("Opcode($methodName, $opcodeId, $format)");
	}
}