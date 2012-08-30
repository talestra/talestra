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
	
	static private function setKey(key:Int, set:Bool):Void {
		if (set) {
			pressing.set(key, null);
		} else {
			pressing.remove(key);
		}
	}
	
	static private function onKeyDown(e:KeyboardEvent):Void  {
		setKey(e.keyCode, true);
	}
	
	static private function onKeyUp(e:KeyboardEvent):Void  {
		setKey(e.keyCode, false);
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
		setKey(Keys.Left, false);
		setKey(Keys.Right, false);
		setKey(Keys.Up, false);
		setKey(Keys.Down, false);
	}
	
	static private inline var deltaThresold:Int = 40;

	static private function onMouseMove(e:MouseEvent):Void {
		if (e.buttonDown) {
			BraveLog.trace(Std.format("onMouseMove : ${e.stageX}, ${e.stageY}"));
			mouseCurrent = new Point(e.stageX, e.stageY);
			var offset:Point = mouseCurrent.subtract(mouseStart);
			
			BraveLog.trace(Std.format("--> ${offset.x}, ${offset.y}"));
			
			setKey(Keys.Left, (offset.x < -deltaThresold));
			setKey(Keys.Right, (offset.x > deltaThresold));
			setKey(Keys.Up, (offset.y < -deltaThresold));
			setKey(Keys.Down, (offset.y > deltaThresold));
		}
	}
}