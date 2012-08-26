using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class Script
	{
		public struct Opcode
		{
			public int OpcodeNum;
			public string OpcodeName;
			public string Format;
		}

		public enum ComparisionOps
		{
			Distinct = 0,
			Equals = 1,
			GreaterEqual = 2,
			LessEqual = 3,
			Greater = 4,
			Less = 5,
		}

		public enum AritmeticOps
		{
			Assign = 0,
			Add = 1,
			Substract = 2,
			Multiply = 3,
			Divide = 4,
			Module = 5,
			And = 6,
			Or = 7,
		}

		public enum Direction
		{
			Down = 0,
			Left = 1,
			Up = 2,
			Right = 3,
		}

		public enum Charas
		{
			Player = 0,
			Shell = 1,
			Alicia = 3,
		}

		Stream Stream;
		BinaryReader BinaryReader;
		public int[] Variables;

		public struct Instruction
		{
			public uint Position;
			public Opcode Opcode;
			public object[] Parameters;

			static public string Serialize(object Parameter)
			{
				if (Parameter.GetType() == typeof(string))
				{
					return String.Format("\"{0}\"", Parameter);
				}
				else
				{
					return Parameter.ToString();
				}
			}

			public override string ToString()
			{
				return String.Format("{0:X8}: {1}({2})", Position, Opcode.OpcodeName, String.Join(", ", Parameters.Select(Parameter => Serialize(Parameter))));
			}
		}

		public Script(Stream Stream)
		{
			this.Stream = Stream;
			this.BinaryReader = new BinaryReader(Stream);
			this.Stream.Position = 8;
		}

		public IEnumerable<Instruction> ParseAll()
		{
			while (Stream.Position < Stream.Length)
			{
				yield return ParseSingle();
			}
		}

		public struct VariableReference
		{
			public ushort Index;

			public override string ToString()
			{
				return String.Format("VariableReference({0})", Index);
			}
		}

		public struct SpecialReference
		{
			public ushort Index;

			public override string ToString()
			{
				return String.Format("SpecialReference({0})", Index);
			}
		}

		public struct LabelReference
		{
			public uint Offset;

			public override string ToString()
			{
				return String.Format("LabelReference({0:X8})", Offset);
			}
		}


		public Instruction ParseSingle()
		{
			var InstructionPosition = Stream.Position;
			var OpcodeNum = BinaryReader.ReadUInt16();
			if (!Opcodes.ContainsKey(OpcodeNum))
			{
				throw(new NotImplementedException(String.Format("Unhandled opcode 0x{0:X2}", OpcodeNum)));
			}
			var Opcode = Opcodes[OpcodeNum];
			var Params = new List<object>();

			foreach (var FormatChar in Opcode.Format)
			{
				switch (FormatChar)
				{
					case 's': Params.Add(ReadString()); break;
					case 'S': Params.Add(ReadStringz()); break;
					case '1': Params.Add(BinaryReader.ReadByte()); break;
					case '7': Params.Add((AritmeticOps)BinaryReader.ReadByte()); break;
					case '9': Params.Add((ComparisionOps)BinaryReader.ReadByte()); break;
					case '2': Params.Add(BinaryReader.ReadInt16()); break;
					case 'v': Params.Add(new VariableReference() { Index = BinaryReader.ReadUInt16() }); break;
					case '4': Params.Add(BinaryReader.ReadUInt32()); break;
					case 'L': Params.Add(new LabelReference() { Offset = BinaryReader.ReadUInt32() }); break;
					case 'P':
						{
							var ParamType = BinaryReader.ReadByte();
							object Value = null;
							switch (ParamType)
							{
								case 0x00: Value = BinaryReader.ReadSByte(); break;
								case 0x10: Value = BinaryReader.ReadByte(); break;
								case 0x20: Value = BinaryReader.ReadInt16(); break;
								case 0x40: Value = BinaryReader.ReadInt32(); break;
								case 0x01: Value = new VariableReference() { Index = BinaryReader.ReadUInt16() }; break;
								case 0x02: Value = new SpecialReference() { Index = BinaryReader.ReadUInt16() }; break;
								default: throw (new NotImplementedException(String.Format("Invalid param type {0}", ParamType)));
							}

							Params.Add(Value);
						}
						break;
					default:
						throw(new NotImplementedException(String.Format("Invalid format '{0}'", FormatChar)));
				}
			}

			return new Instruction()
			{
				Position = (uint)InstructionPosition,
				Opcode = Opcode,
				Parameters = Params.ToArray(),
			};
		}

		static public readonly Dictionary<int, Opcode> Opcodes = new Dictionary<int, Opcode>();

		static private void AddOpcode(int OpcodeNum, string OpcodeName, string Format)
		{
			Opcodes.Add(OpcodeNum, new Opcode() { OpcodeNum = OpcodeNum, OpcodeName = OpcodeName, Format = Format });
			//Opcodes.
		}

		static Script()
		{
			// 00-01 : Function
			AddOpcode(0x01, "FUNCTION_DEF", "SL");

			// 00-1F
			AddOpcode(0x02, "JUMP_IF", "PP9L");
			AddOpcode(0x03, "OP_03", "ss1L");
			AddOpcode(0x04, "OP_04", "L");
			AddOpcode(0x05, "RETURN", "4"); // Return?
			AddOpcode(0x07, "OP_07", ""); // FLOW. Return?
			AddOpcode(0x08, "DEBUG_MESSAGE", "");
			AddOpcode(0x09, "OP_09", "");
			AddOpcode(0x0A, "OP_0A", "P");
			AddOpcode(0x0B, "OP_0B", "P");
			AddOpcode(0x0C, "OP_0C", "P");
			AddOpcode(0x0D, "OP_0D", "PP");
			AddOpcode(0x0F, "ARITMETIC_OP", "v7P");
			AddOpcode(0x10, "OP_10", "11s");
			AddOpcode(0x11, "VAR_INCREMENT", "v");
			AddOpcode(0x12, "VAR_DECREMENT", "v");
			AddOpcode(0x13, "RANDOM", "vP");
			AddOpcode(0x14, "OP_14", "PP");
			AddOpcode(0x15, "OP_15", "12");
			AddOpcode(0x17, "MUSIC_PLAY", "P");
			AddOpcode(0x18, "OP_18", "P");
			AddOpcode(0x19, "OP_19", "PP");
			AddOpcode(0x1A, "OP_1A", "P");
			AddOpcode(0x1B, "OP_1B", "PP");
			AddOpcode(0x1C, "MUSIC_STOP", "");
			AddOpcode(0x1D, "COMMENT", "s");
			AddOpcode(0x1E, "OP_1E", "sP");

			// 20-33
			AddOpcode(0x21, "SCRIPT", "s"); // Delay?
			AddOpcode(0x22, "OP_22", "");
			AddOpcode(0x23, "OP_23", "");
			AddOpcode(0x24, "MAP_SET", "s");
			AddOpcode(0x25, "OP_25", "sP");
			AddOpcode(0x26, "OP_26", "PPPss");
			AddOpcode(0x27, "OP_27", "PPPPPss");
			AddOpcode(0x28, "IMAGE_SET", "s");
			AddOpcode(0x29, "OP_29", "PPs");
			AddOpcode(0x2A, "FADE_OUT", "4");
			AddOpcode(0x2B, "OP_2B", "4");
			AddOpcode(0x2C, "OP_2C", "4");
			AddOpcode(0x2D, "OP_2D", "P"); // Lot of stuff
			AddOpcode(0x2E, "OP_2E", "-");
			AddOpcode(0x2F, "TEXT_PUT", "sss");
			AddOpcode(0x30, "DELAY", "P"); // Delay?
			AddOpcode(0x31, "FADE_TO_MAP", "P");

			// 34-42
			AddOpcode(0x35, "TITLE_SET", "s");
			AddOpcode(0x36, "OP_36", "s");
			AddOpcode(0x37, "OP_37", "");
			AddOpcode(0x38, "OP_38", "Psss");
			AddOpcode(0x39, "TEXT_PUT_WITH_FACE", "Psss");
			AddOpcode(0x3A, "OP_3A", "PPPsss");
			AddOpcode(0x3B, "OP_3B", "");
			AddOpcode(0x3C, "OP_3C", "");
			AddOpcode(0x3D, "ANIMATION_WAIT", "");
			AddOpcode(0x3E, "OPTION_START", "Ps");
			AddOpcode(0x3F, "OPTION_ITEM", "s");
			AddOpcode(0x40, "OPTION_SHOW", ""); // FLOW?
			AddOpcode(0x41, "OP_41", "PP");

			// 43--4F
			AddOpcode(0x44, "TEXT_PUT_44", "s"); // X40 = 0
			AddOpcode(0x45, "OP_45", ""); // X40 = 1
			AddOpcode(0x46, "OP_46", "s"); // X40 = 2
			AddOpcode(0x47, "OP_47", "");
			AddOpcode(0x48, "TITLE_SHOW", "s");
			AddOpcode(0x49, "OP_49", "PPPPPP");
			AddOpcode(0x4A, "MAP_CELL_SET_ATTRIBUTE_FOR?", "PPPP"); // Id, X, Y, Attribute (255 blocked, 0 no blocked)
			AddOpcode(0x4B, "OP_4B", "PPPPPP");
			AddOpcode(0x4C, "OP_4C", "PPPP");
			AddOpcode(0x4D, "OP_4D", "PPPP");
			AddOpcode(0x4E, "TRIGGER_SET", "PPPP");

			// 50-91
			AddOpcode(0x51, "CHARA_UNK_51", "PP");
			AddOpcode(0x52, "UNK_52", "P");
			AddOpcode(0x53, "PLAYER_SPAWN", "PPPPP"); // Id, 0, X, Y, Direction
			AddOpcode(0x54, "UNK_54", "vP");
			AddOpcode(0x55, "CHARA_SET", "vP");
			AddOpcode(0x56, "UNK_56", "v");
			AddOpcode(0x57, "CHARA_SPAWN", "PPPPP"); // Id, 0, X, Y, Direction
			AddOpcode(0x58, "UNK_58", "");
			AddOpcode(0x59, "GROUP_MOVE", "PPP"); // X, Y, Direction
			AddOpcode(0x5A, "UNK_5A", "vP");
			AddOpcode(0x5B, "UNK_5B", "P");
			AddOpcode(0x5C, "UNK_5C", "PP");
			AddOpcode(0x5D, "UNK_5D", "PP");
			AddOpcode(0x5E, "UNK_5E", "PP");
			AddOpcode(0x5F, "UNK_5F", "PP");
			AddOpcode(0x60, "UNK_60", "P");
			AddOpcode(0x61, "UNK_61", "P"); // Increment up to 999999999?
			AddOpcode(0x62, "UNK_62", "P");
			AddOpcode(0x63, "UNK_63", "P");
			AddOpcode(0x64, "UNK_64", "P");
			AddOpcode(0x65, "UNK_65", ""); // memset(byte_518558, 0x1010101u, 40u);
			AddOpcode(0x66, "UNK_66", "PPPPP");
			AddOpcode(0x67, "ENEMY_SPAWN", "PPPPPP"); // Id, ???, 0, X, Y, Direction
			AddOpcode(0x68, "UNK_68", "PPPPPPPP");
			AddOpcode(0x69, "UNK_69", "PP");
			AddOpcode(0x6A, "UNK_6A", "P");
			AddOpcode(0x6B, "UNK_6B", "PP");
			AddOpcode(0x6C, "UNK_6C", ""); // = 2
			AddOpcode(0x6D, "UNK_6D", ""); // = 4
			AddOpcode(0x6E, "UNK_6E", ""); // = 0
			AddOpcode(0x6F, "UNK_6F", "P");
			AddOpcode(0x70, "UNK_70", "PP");
			AddOpcode(0x71, "UNK_71", "PPPPPPPPP");
			AddOpcode(0x72, "UNK_72", "PP");
			AddOpcode(0x73, "UNK_73", "PP");
			AddOpcode(0x74, "UNK_74", "PPP");
			AddOpcode(0x75, "CHARA_START", "P");
			AddOpcode(0x76, "CHARA_MOVE_TO", "PPP");
			AddOpcode(0x77, "CHARA_FACE_TO", "PP");
			AddOpcode(0x78, "UNK_78", "PP");
			AddOpcode(0x79, "UNK_79", "P");
			AddOpcode(0x7A, "UNK_7A", "PPP");
			AddOpcode(0x7B, "UNK_7B", "PPPP");
			AddOpcode(0x7C, "UNK_7C", "PP");
			AddOpcode(0x7D, "UNK_7D", "PP");
			AddOpcode(0x7E, "UNK_7E", "PPP");
			AddOpcode(0x7F, "UNK_7F", "PPPP");
			AddOpcode(0x80, "UNK_80", "PP");
			AddOpcode(0x81, "UNK_81", "P");
			AddOpcode(0x82, "UNK_82", "P");
			AddOpcode(0x83, "UNK_83", "PP");
			AddOpcode(0x84, "UNK_84", "PP");
			AddOpcode(0x85, "UNK_85", "P");
			AddOpcode(0x86, "CHARA_EVENT_SET", "PP");
			AddOpcode(0x87, "UNK_87", "PP");
			AddOpcode(0x88, "UNK_88", "PPP");
			AddOpcode(0x89, "UNK_89", "P");
			AddOpcode(0x8A, "UNK_8A", "P");
			AddOpcode(0x8B, "CHARA_EMOJI", "PPP"); // CharaId, ChatDirection, Emoji (PG_MAIN)
			AddOpcode(0x8C, "UNK_8C", "P");
			AddOpcode(0x8D, "UNK_8D", "PP");
			AddOpcode(0x8E, "UNK_8E", "PP");
			AddOpcode(0x8F, "CHARA_STOP", "P");
			AddOpcode(0x90, "CHARA_DONE", "P");

			// 92
			AddOpcode(0x92, "END", "");
		}

		public void FUNCTION_DEF(string Name, int End)
		{
		}

		public void JUMP_IF(int Left, int Right, int Operation)
		{
		}

		public void CHARA_MOVE_TO(int CharaId, int X, int Y)
		{
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="CharaId"></param>
		/// <param name="X"></param>
		/// <param name="Y"></param>
		/// <param name="EventId">If -1, it will remove the event</param>
		public void TRIGGER_SET(int CharaId, int X, int Y, int EventId)
		{
		}

		//static public readonly Opcode[] Opcodes = 

		/// <summary>
		/// 
		/// </summary>
		/// <param name="BinaryReader"></param>
		public void ProcessStep()
		{
			var Opcode = BinaryReader.ReadUInt16();

			switch (Opcode)
			{
				case 0x92: // Exit? / Nop?
					break;
			}

			if (Opcode >= 0x01 && Opcode <= 0x1F)
			{
				ProcessStepFlow(Opcode);
			}
			else if (Opcode >= 0x21 && Opcode <= 0x2F)
			{
				ProcessStepText(Opcode);
			}
			else if (Opcode >= 0x40 && Opcode <= 0x4F)
			{
				ProcessStep40(Opcode);
			}
			else if (Opcode >= 0x50 && Opcode <= 0x91)
			{
				ProcessStep50(Opcode);
			}
			else
			{
				throw(new NotImplementedException());
			}
		}

		public int ReadParameterXXX(ushort N)
		{
			throw(new NotImplementedException());
		}

		public string ReadStringz()
		{
			var MemoryStream = new MemoryStream();
			byte Byte;
			while ((Byte = BinaryReader.ReadByte()) != 0)
			{
				MemoryStream.WriteByte(Byte);
			}
			return Encoding.Default.GetString(MemoryStream.ToArray());
		}

		public string ReadString()
		{
			var Unk = BinaryReader.ReadByte();
			if (Unk == 0)
			{
				return ReadStringz();
			}
			else
			{
				throw(new NotImplementedException(String.Format("String with preppend 0x{0:X2}", Unk)));
			}
		}

		public int ReadParameter()
		{
			switch (BinaryReader.ReadByte())
			{
				case 0x00: return (int)BinaryReader.ReadSByte();
				case 0x10: return (int)BinaryReader.ReadByte();
				case 0x20: return (int)BinaryReader.ReadInt16();
				case 0x40: return (int)BinaryReader.ReadInt32();
				case 0x01: return Variables[BinaryReader.ReadUInt16()];
				case 0x02: return ReadParameterXXX(BinaryReader.ReadUInt16());
				default: return 0;
			}
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="Opcode"></param>
		/// <param name="BinaryReader"></param>
		public void ProcessStepFlow(ushort Opcode)
		{
			switch (Opcode)
			{
				// FUNCTION_DEF
				case 0x01:
					{
						var FunctionName = ReadString();
						var FunctionEnd = BinaryReader.ReadUInt32();
					}
					break;
				// JUMP_IF
				case 0x02:
					{
						int Left = ReadParameter();
						int Right = ReadParameter();
						var SubOpcode = BinaryReader.ReadByte();
						bool Result = false;

						switch (SubOpcode)
						{
							case 0x00: Result = !(Left != Right); break;
							case 0x01: Result = !(Left == Right); break;
							case 0x02: Result = !(Left >= Right); break;
							case 0x03: Result = !(Left <= Right); break;
							case 0x04: Result = !(Left > Right); break;
							case 0x05: Result = !(Left < Right); break;
							default: throw(new NotImplementedException());
						}

						var Label = BinaryReader.ReadUInt32();
					}
					break;
				default:
					throw(new NotImplementedException());
			}
		}

		public void ProcessStepText(ushort Opcode)
		{
			switch (Opcode)
			{
				// SET_MAP
				case 0x24:
					{
						var MapName = ReadString();
					}
					break;
				// SET_IMAGE
				case 0x28:
					{
						var ImageName = ReadString();
					}
					break;
				// PUT_TEXT?
				case 0x2F:
					{
						var Audio = ReadString();
						var Title = ReadString();
						var Text = ReadString();
					}
					break;
				default:
					throw (new NotImplementedException());
			}
		}

		public void ProcessStep40(ushort Opcode)
		{
			switch (Opcode)
			{
				// SET_SAVE_TITLE
				case 0x44:
					{
						var Title = ReadString();
					}
					break;
				default:
					throw (new NotImplementedException());
			}
		}
		public void ProcessStep50(ushort Opcode)
		{
			switch (Opcode)
			{
				// ????
				case 0x53:
					{
						var Param1 = ReadParameter();
						var Param2 = ReadParameter();
						var Param3 = ReadParameter();
						var Param4 = ReadParameter();
						var Param5 = ReadParameter();
					}
					break;
				default:
					throw(new NotImplementedException());
			}
		}
	}
}
