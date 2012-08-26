package brave;

/**
 * ...
 * @author 
 */

class GameState 
{
	public var variables:Array<Variable>;
	public var eventId:Int = 0;

	public function new() 
	{
		variables = new Array<Variable>();
		for (n in 0 ... 10000) variables.push(new Variable());
	}
	
}