using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class Lz
	{
		static private byte[] ExpectedMagic = new byte[] { 0x53, 0x5A, 0x44, 0x44, 0x88, 0xF0, 0x27, 0x33, 0x41, 0x00 };

		const int N = 4096;
		const int F = 16;
		const int THRESHOLD = 3;

		static public byte[] DecodeStream(Stream Stream)
		{
			var BinaryReader = new BinaryReader(Stream);
			var Magic = BinaryReader.ReadBytes(10);
			if (!Magic.SequenceEqual(ExpectedMagic)) throw(new InvalidDataException("Invalid LZ file"));
			var UncompressedSize = BinaryReader.ReadUInt32();
			var Buffer = new byte[N];
			var Input = BinaryReader.ReadBytes((int)(Stream.Length - Stream.Position));
			var Output = new byte[UncompressedSize];
			int InputPos = 0;
			int OutputPos = 0;

			int i = N - F;

			while (InputPos < Input.Length)
			{
				var Bits = ((int)Input[InputPos++]) | 0x100;
				while (Bits != 1)
				{
					var CurrentBit = ((Bits & 1) != 0);
					Bits >>= 1;
					
					if (CurrentBit)
					{
						Output[OutputPos++] = Buffer[i] = Input[InputPos++];
						i = (i + 1) & (N - 1);
					}
					else
					{
						if (InputPos >= Input.Length) break;
						var j = (int)Input[InputPos++];
						var len = (int)Input[InputPos++];
						j += (len & 0xF0) << 4;
						len = (len & 15) + 3;
						while (len-- > 0)
						{
							Output[OutputPos++] = Buffer[i] = Buffer[j];
							j=(j+1)&(N-1);
							i=(i+1)&(N-1);
						}
					}
				}
			}

			return Output;
		}
	}
}
