package brave.script;

/**
 * ...
 * @author 
 */

class Opcode {
	public var methodName:String;
	public var opcodeId:Int;
	public var format:String;
	public var unimplemented:Bool;
	
	public function new(methodName:String, opcodeId:Int, format:String, unimplemented:Bool) {
		this.methodName = methodName;
		this.opcodeId = opcodeId;
		this.format = format;
		this.unimplemented = unimplemented;
	}
	
	public function toString():String {
		return Std.format("Opcode(name=$methodName, id=$opcodeId, format=$format, unimplemented=$unimplemented)");
	}
}