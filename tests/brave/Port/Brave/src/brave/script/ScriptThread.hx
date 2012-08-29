package brave.script;
import brave.GameState;
import brave.GameThreadState;
import haxe.Log;

/**
 * ...
 * @author 
 */

class ScriptThread implements IScriptThread
{
	public var gameState:GameState;
	public var gameThreadState:GameThreadState;
	private var scriptReader:ScriptReader;
	private var scriptInstructions:ScriptInstructions;
	public var executing:Bool;
	public var waitingAsync:Bool;

	public function new(gameState:GameState) 
	{
		this.gameState = gameState;
		this.gameThreadState = new GameThreadState();
		this.scriptInstructions = new ScriptInstructions(this);
	}
	
	public function setScript(script:Script):Void {
		clearStack();
		this.scriptReader = new ScriptReader(script);
		this.scriptReader.position = 8;
		this.gameThreadState.eventId = 0;
		executing = false;
		waitingAsync = false;
	}
	
	public function execute():Void {
		//if (!executing || waitingAsync)
		Log.trace(Std.format("execute at ${scriptReader.position}"));
		{
			while (scriptReader.hasMoreInstructions()) {
				executing = true;
				waitingAsync = false;
				
				switch (executeNextInstruction()) {
					case -2: executing = false; Log.trace("/execute(-2)"); return;
					case -3: waitingAsync = true; Log.trace("/execute(-3)"); return;
				}
			}
			
			executing = false;
			waitingAsync = false;
		}
		Log.trace("/execute(0)");
	}
	
	private function executeNextInstruction():Int {
		var instruction:Instruction = scriptReader.readInstruction(this);
		var result:Dynamic = instruction.call(scriptInstructions);
		
		// End Script
		if (result == -1) {
			Log.trace("End Executing");
			this.scriptReader.position = 8;
			return -1;
		}
		
		// Enable play
		if (result == -2) {
			Log.trace("Enable play");
			return -2;
		}
		
		return instruction.async ? -3 : 0;
	}
	
	var stack:Array<Int>;
	
	public function pushStack(value:Int):Void {
		stack.push(value);
	}
	
	public function popStack():Int {
		return stack.pop();
	}
	
	public function clearStack():Void {
		stack = [];
	}


	public function jump(offset:Int):Void {
		scriptReader.position = offset;
	}
	
	public function getVariable(index:Int):Variable {
		return gameState.variables[index];
	}
	
	public function getSpecial(index:Int):Dynamic {
		//return new SpecialValue(index);
		//throw(new Error("Unimplemented"));
		switch (index) {
			case 0: return gameThreadState.eventId;
			//case 4: return 1;
			case 4: return 0;
			default:
				Log.trace(Std.format("getSpecial($index)"));
				return 0;
		}
	}
}