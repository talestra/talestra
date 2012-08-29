package brave;

/**
 * ...
 * @author 
 */

class AsyncList 
{
	public var actions:Array<Dynamic>;
	public var running:Bool = false;

	public function new() 
	{
		actions = [];
	}
	
	public function addAction(action:(Void -> Void) -> Void):Void {
		actions.push(action);
		if (!running) {
			next();
		}
	}
	
	public function next():Void {
		if (actions.length > 0) {
			var func = actions.shift();
			running = true;
			func(next);
		} else {
			running = false;
		}
	}
}