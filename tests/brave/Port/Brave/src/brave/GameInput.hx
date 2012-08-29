package brave;
import nme.events.KeyboardEvent;
import nme.Lib;

/**
 * ...
 * @author 
 */

class GameInput 
{
	static var pressing:IntHash<Void>;

	private function new() 
	{
	}
	
	static public function init() {
		pressing = new IntHash<Void>();
		Lib.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Lib.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}
	
	static public function isPressing(keyCode:Int):Bool {
		return pressing.exists(keyCode);
	}
	
	static private function onKeyDown(e:KeyboardEvent):Void  {
		pressing.set(e.keyCode, null);
	}
	
	static private function onKeyUp(e:KeyboardEvent):Void  {
		pressing.remove(e.keyCode);
	}
}