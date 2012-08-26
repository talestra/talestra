package brave.script;
import brave.GameState;
import brave.GameThreadState;

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

	public function new(gameState:GameState) 
	{
		this.gameState = gameState;
		this.gameThreadState = new GameThreadState();
		this.scriptInstructions = new ScriptInstructions(this);
	}
	
	public function setScript(script:Script):Void {
		this.scriptReader = new ScriptReader(script);
	}
	
	public function execute():Void {
		while (scriptReader.hasMoreInstructions()) {
			if (executeNextInstruction()) break;
		}
	}
	
	private function executeNextInstruction():Bool {
		var instruction:Instruction = scriptReader.readInstruction(this);
		instruction.call(scriptInstructions);
		return instruction.async;
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
			default:
				return 0;
		}
	}
}