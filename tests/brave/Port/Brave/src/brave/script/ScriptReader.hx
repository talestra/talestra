package brave.script;
import brave.ByteArrayUtils;
import haxe.Log;
import nme.errors.Error;

/**
 * ...
 * @author 
 */

class ScriptReader 
{
	public var position:Int;
	public var script:Script;

	public function new(script:Script) 
	{
		this.script = script;
		this.position = 8;
	}
	
	public function readAllInstructions():Void {
		while (hasMoreInstructions()) {
			var instruction:Instruction = readInstruction(null);
			Log.trace(instruction);
		}
	}
	
	public function hasMoreInstructions():Bool {
		//return script.data.bytesAvailable > 0;
		return script.data.position < script.data.length;
	}
	
	public function readInstruction(scriptThread:IScriptThread):Instruction {
		script.data.position = position;
		var opcodeId:Int = read2();
		var opcode:Opcode = ScriptOpcodes.getOpcodeWithId(opcodeId);
		var parameters:Array<Dynamic> = readFormat(opcode.format, scriptThread);
		var async:Bool = (opcode.format.indexOf("<") != -1);
		position = script.data.position;
		return new Instruction(opcode, parameters, async);
	}
	
	private function readFormat(format:String, scriptThread:IScriptThread):Array<Dynamic> {
		var params = new Array<Dynamic>();

		//Log.trace("readFormat : '" + format + "'");

		for (n in 0 ... format.length) {
			var char:String = format.charAt(n);
			//Log.trace(" : '" + char + "' " + n);
			params.push(readFormatChar(char, scriptThread));
		}
		
		return params;
	}
	
	private function readFormatChar(char:String, scriptThread:IScriptThread):Dynamic {
		switch (char) {
			case '<': return (scriptThread != null) ? scriptThread.execute : null;
			case 's': return readString();
			case 'S': return readStringz();
			case 'L': return read4();
			case '4': return read4();
			case 'v': {
				var index = read2();
				if (scriptThread != null) {
					return scriptThread.getVariable(index);
				} else {
					return Std.format("VARIABLE($index)");
				}
			}
			case 'P': return readParam(scriptThread);
			case '7': return read1();
			case '9': return read1();
			default: {
				throw(new Error(Std.format("Invalid format '${char}'")));
			}
		}
	}

	private function readParam(scriptThread:IScriptThread):Dynamic {
		var paramType:Int = read1();
		
		switch (paramType) {
			case 0x00: return read1Signed();
			case 0x10: return read1();
			case 0x20: return read2();
			case 0x40: return read4();
			case 0x01:
				var index = read2();
				if (scriptThread != null) {
					return scriptThread.getVariable(index).getValue();
				} else {
					return Std.format("VARIABLE($index)");
				}
			case 0x02:
				var index = read2();
				if (scriptThread != null) {
					return scriptThread.getSpecial(index);
				} else {
					return Std.format("SPECIAL($index)");
				}
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
		return StringTools.replace(ByteArrayUtils.readStringz(script.data), "@n;", "\n");
	}

	private function read1():Int {
		return script.data.readUnsignedByte();
	}

	private function read1Signed():Int {
		//return script.data.readByte();
		var byte:Int = script.data.readUnsignedByte();
		if ((byte & 0x80) != 0) {
			return byte | 0xFFFFFF00;
		} else {
			return byte;
		}
	}

	private function read2():Int {
		return script.data.readUnsignedShort();
	}

	private function read4():Int {
		return script.data.readUnsignedInt();
	}
}