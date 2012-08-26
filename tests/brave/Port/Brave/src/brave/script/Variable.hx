package brave.script;

/**
 * ...
 * @author 
 */

class Variable
{
	private var value:Dynamic;

	public function new(?value:Dynamic) 
	{
		this.value = value;
	}
	
	public function getValue():Dynamic {
		return this.value;
	}
	
	public function setValue(value:Dynamic):Void {
		this.value = value;
	}
	
	public function toString():String {
		return Std.format("Variable($value)");
	}
}