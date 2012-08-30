package brave;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.geom.Point;
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
		Lib.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		Lib.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		Lib.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
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
	
	static private var mouseCurrent:Point;
	static private var mouseStart:Point;
	
	static private function onMouseDown(e:MouseEvent):Void {
		if (e.buttonDown) {
			BraveLog.trace(Std.format("onMouseDown : ${e.stageX}, ${e.stageY}"));
			mouseStart = new Point(e.stageX, e.stageY);
			//e.stageX
		}
	}

	static private function onMouseUp(e:MouseEvent):Void {
		BraveLog.trace(Std.format("onMouseUp : ${e.stageX}, ${e.stageY}"));
		Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, 0, Keys.Left));
		Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, 0, Keys.Right));
		Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, 0, Keys.Up));
		Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, 0, Keys.Down));
	}

	static private function onMouseMove(e:MouseEvent):Void {
		if (e.buttonDown) {
			BraveLog.trace(Std.format("onMouseMove : ${e.stageX}, ${e.stageY}"));
			mouseCurrent = new Point(e.stageX, e.stageY);
			var offset:Point = mouseCurrent.subtract(mouseStart);
			
			BraveLog.trace(Std.format("--> ${offset.x}, ${offset.y}"));
			
			if (offset.x < -64) Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keys.Left));
			if (offset.x > 64) Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keys.Right));
			if (offset.y < -64) Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keys.Up));
			if (offset.y > 64) Lib.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keys.Down));
		}
	}
}