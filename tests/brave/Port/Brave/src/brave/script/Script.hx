package brave.script;
import brave.BraveAssets;
import formats.Decrypt;
import haxe.Log;
import haxe.rtti.Meta;
import nme.Assets;
import nme.errors.Error;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author 
 */

class Script 
{
	public function new() 
	{
		var metas = Meta.getFields(ScriptInstructions);
		//Log.trace(metas.JUMP_IF);
		
		opcodesById = new IntHash<Opcode>();
		scriptInstructions = new ScriptInstructions(this);
		gameState = new GameState();
		
		for (key in Reflect.fields(metas)) {
			var opcodeAttribute:Dynamic = Reflect.getProperty(metas, key).Opcode;
			if (opcodeAttribute != null) {
				if (opcodeAttribute.length == 3) {
					addOpcode(key, opcodeAttribute[0], opcodeAttribute[2]);
				} else {
					addOpcode(key, opcodeAttribute[0], opcodeAttribute[1]);
				}
			}
		}
	}
	
	private function addOpcode(methodName:String, opcodeId:Int, format:String) {
		//Reflect.callMethod(this, 
		//Log.trace(Std.format("$methodName, $opcodeId, $format"));
		opcodesById.set(opcodeId, new Opcode(methodName, opcodeId, format));
	}
	
	private var scriptInstructions:ScriptInstructions;
	private var opcodesById:IntHash<Opcode>;
	private var gameState:GameState;
	private var data:ByteArray;

	public function setScriptWithName(name:String):Void {
		setScriptWithByteArray(Decrypt.decryptDataWithKey(BraveAssets.getBytes(Std.format("scenario/${name}.dat")), Decrypt.key23));
	}

	public function setScriptWithByteArray(data:ByteArray):Void {
		this.data = data;
		this.data.endian = Endian.LITTLE_ENDIAN;
		this.data.position = 8;
	}
	
	private function getSpecial(index:Int):Dynamic {
		//return new SpecialValue(index);
		//throw(new Error("Unimplemented"));
		switch (index) {
			case 0: return gameState.eventId;
			default:
				return 0;
		}
	}
	
	public function execute():Void {
		while (data.bytesAvailable > 0) {
			executeNextInstruction();
		}
	}
	
	public function executeNextInstruction():Void {
		var instruction:Instruction = readInstruction();
		instruction.call(scriptInstructions);
	}
	
	public function jump(offset:Int):Void {
		this.data.position = offset;
	}
	
	private function readInstruction():Instruction {
		var opcodeId:Int = read2();
		var opcode:Opcode = opcodesById.get(opcodeId);
		if (opcode == null) throw(new Error(Std.format("Unknown opcode ${opcodeId}")));
		var parameters:Array<Dynamic> = readFormat(opcode.format);
		
		return new Instruction(opcode, parameters);
	}
	
	private function readFormat(format:String):Array<Dynamic> {
		var params = new Array<Dynamic>();

		//Log.trace("readFormat : '" + format + "'");

		for (n in 0 ... format.length) {
			var char:String = format.charAt(n);
			//Log.trace(" : '" + char + "' " + n);
			params.push(readFormatChar(char));
		}
		
		return params;
	}

	private function readFormatChar(char:String):Dynamic {
		switch (char) {
			case 's': return readString();
			case 'S': return readStringz();
			case 'L': return read4();
			case '4': return read4();
			case 'v': {
				var index = read2();
				var variable = gameState.variables[index];
				return variable;
			}
			case 'P': return readParam();
			case '7': return read1();
			case '9': return read1();
			default: {
				throw(new Error(Std.format("Invalid format '${char}'")));
			}
		}
	}

	private function readParam():Dynamic {
		var paramType:Int = read1();
		
		switch (paramType) {
			case 0x00: return read1Signed();
			case 0x10: return read1();
			case 0x20: return read2();
			case 0x40: return read4();
			case 0x01: return gameState.variables[read2()].getValue();
			case 0x02: return getSpecial(read2());
			default: throw(new Error(Std.format("Invalid format ${paramType}")));
		}
	}

	private function readString():String {
		var v:Int = read1();
		if (v == 0) {
			return readStringz();
		} else {
			throw(new Error("Unimplemented"));
		}
	}

	private function readStringz():String {
		var v:Int;
		var str:String = "";
		while ((v = read1()) != 0) {
			str += String.fromCharCode(v);
		}
		return str;
	}

	private function read1():Int {
		return this.data.readUnsignedByte();
	}

	private function read1Signed():Int {
		return this.data.readByte();
	}

	private function read2():Int {
		return this.data.readUnsignedShort();
	}

	private function read4():Int {
		return this.data.readUnsignedInt();
	}
}