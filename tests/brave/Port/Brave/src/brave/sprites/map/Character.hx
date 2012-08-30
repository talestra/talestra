package brave.sprites.map;
import brave.Animation;
import brave.AsyncList;
import brave.BraveAssets;
import brave.GameInput;
import brave.GameThreadState;
import brave.GraphicUtils;
import brave.Keys;
import brave.map.Cell;
import brave.map.Map;
import brave.map.Tileset;
import brave.MathEx;
import brave.script.ScriptThread;
import haxe.Log;
import haxe.Timer;
import nme.display.Sprite;
import nme.events.Event;
import nme.Lib;

/**
 * ...
 * @author 
 */

class Character 
{
	public var id:Int;
	public var imageName:String;
	public var tileset:Tileset;
	public var x:Int;
	public var y:Int;
	public var sprite:Sprite;
	public var direction:Int;
	public var frame:Int;
	public var enableMovement:Bool = false;
	public var alive:Bool = true;
	var frameNums:Array<Int>;
	var actions:AsyncList;
	var mapSprite:MapSprite;
	
	public function new(mapSprite:MapSprite, id:Int, imageName:String, x:Int, y:Int, direction:Int = 0) 
	{
		this.mapSprite = mapSprite;
		this.id = id;
		this.imageName = imageName;
		this.tileset = new Tileset(1, imageName);
		this.x = x;
		this.y = y;
		this.direction = direction;
		this.frame = 0;
		this.sprite = new Sprite();
		this.frameNums = [0, 1, 0, 2];
		
		this.actions = new AsyncList();
		this.events = new IntHash<Dynamic>();
		
		Lib.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		//moveTest();
	}
	
	public function loadImageAsync(done:Void -> Void):Void {
		tileset.loadDataAsync(done);
	}
	
	private var events:IntHash<Dynamic>;
	
	public function kill():Void {
		BraveLog.trace("killed!");
		this.alive = false;
		this.direction = 5;
		checkEventWithKey(-1);
	}

	private function _setEvent(keyId:Int, scriptThread:ScriptThread, eventId:Int):Void {
		if (eventId == -1) {
			events.remove(keyId);
		} else {
			events.set(keyId, [scriptThread, eventId]);
		}
	}

	public function setKillEventId(scriptThread:ScriptThread, eventId:Int):Void {
		_setEvent(-1, scriptThread, eventId);
	}
	
	public function setEvent(scriptThread:ScriptThread, x:Int, y:Int, eventId:Int):Void {
		_setEvent(y * 1000 + x, scriptThread, eventId);
		//scriptThread.gameThreadState.eventId = eventId;
		//scriptThread.execute();
	}
	
	private function checkPoint(x:Int, y:Int):Bool {
		var cx = Std.int(x / 40);
		var cy = Std.int(y / 40);
		var cell:Cell = mapSprite.map.get(cx, cy);
		if (cell.info1 != 0) {
			BraveLog.trace(Std.format("Can't move because: ${cell.info1}"));
			if (cell.info1 != 8) {
				return false;
			}
		}
		
		return true;
	}
	
	private function getCellIndex(x:Int, y:Int):Int {
		var cx = Std.int(x / 40);
		var cy = Std.int(y / 40);
		return cy * 1000 + cx;
	}
	
	private function checkEventWithKey(index:Int):Void {
		if (events.exists(index)) {
			var event = events.get(index);
			var scriptThread:ScriptThread = event[0];
			var eventId:Int = event[1];
			scriptThread.gameThreadState.eventId = eventId;
			enableMovement = false;
			scriptThread.jump(8);
			scriptThread.execute();
		}
	}
	
	private function checkEvent(oldX:Int, oldY:Int, newX:Int, newY:Int):Void {
		// Just entered.
		var oldIndex = getCellIndex(oldX, oldY);
		var newIndex = getCellIndex(newX, newY);
		if (oldIndex != newIndex) {
			checkEventWithKey(newIndex);
		}
	}
	
	static public function distance(c1:Character, c2:Character):Float {
		return MathEx._length(c1.x - c2.x, c1.y - c2.y);
	}
	
	private function tryMoveTo(x:Int, y:Int):Bool {
		/*
		if (!checkPoint(x     , y + 0 - 40)) return false;
		if (!checkPoint(x     , y + 0)) return false;
		if (!checkPoint(x + 40, y + 0 - 40)) return false;
		if (!checkPoint(x + 40, y + 0)) return false;
		*/
		if (!checkPoint(x + 20, y + 20)) return false;
		checkEvent(this.x + 20, this.y + 20, x + 20, y + 20);
		
		for (enemy in mapSprite.characters.iterator()) {
			if (enemy.id > 10 && enemy.alive) {
				if (distance(enemy, this) < 32) {
					enemy.kill();
				}
			}
		}
		
		this.x = x;
		this.y = y;
		return true;
	}

	private function tryMoveBy(dx:Int, dy:Int):Bool {
		return tryMoveTo(x + dx, y + dy);
	}
	
	private function onEnterFrame(e:Event):Void {
		if (this.id == 1) {
			frame++;
		}
		
		if (enableMovement) {
			var moving:Bool = false;
			var speed:Int = 4;
			
			if (GameInput.isPressing(Keys.Control)) speed *= 4;
			
			if (GameInput.isPressing(Keys.Down)) { tryMoveBy(0, speed); this.direction = 0; moving = true; }
			if (GameInput.isPressing(Keys.Left)) { tryMoveBy(-speed, 0); this.direction = 1; moving = true; }
			if (GameInput.isPressing(Keys.Up)) { tryMoveBy(0, -speed); this.direction = 2; moving = true; }
			if (GameInput.isPressing(Keys.Right)) { tryMoveBy(speed, 0); this.direction = 3; moving = true; }
			if (moving) {
				this.frame++;
			} else {
				this.frame = 0;
			}
		}
	}
	
	public function actionStart():Void {
		this.actions = new AsyncList();
	}
	
	public function actionMoveTo(destX:Int, destY:Int):Void {
		this.actions.addAction(function(done:Void -> Void) {
			if (Math.abs(x - destX) > Math.abs(y - destY)) {
				this.direction = (destX < x) ? 1 : 3;
			} else {
				this.direction = (destY < y) ? 2 : 0;
			}
			Animation.animate(done, 1, this, { x : destX, y : destY }, Animation.Linear, function(v:Float) {
				frame++;
			});
		});
	}

	public function actionFaceTo(direction:Int):Void {
		this.actions.addAction(function(done:Void -> Void) {
			this.direction = direction;
			done();
		});
	}

	public function actionEventSet(gameThreadState:GameThreadState, eventId:Int):Void {
		this.actions.addAction(function(done:Void -> Void) {
			gameThreadState.eventId = eventId;
			done();
		});
	}

	public function actionDone(done2:Void -> Void):Void {
		this.actions.addAction(function(done:Void -> Void) {
			done();
			done2();
		});
	}

	private function moveTest():Void {
		this.y += 2;
		frame++;
		Timer.delay(moveTest, 30);
	}
	
	public function updateSprite():Void {
		var tileHeight:Int = tileset.cgDbEntry.tileHeight;
		var tileWidth:Int = tileset.cgDbEntry.tileWidth;
		var tileY:Int = this.direction;
		var tileX:Int = frameNums[Std.int(this.frame / 4) % frameNums.length];
		sprite.graphics.clear();
		GraphicUtils.drawBitmapSlice(sprite.graphics, tileset.bitmapData, 0, -tileHeight, tileX * tileWidth, tileY * tileHeight, tileWidth, tileHeight); 
	}
}