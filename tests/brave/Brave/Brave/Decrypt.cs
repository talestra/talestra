using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class Decrypt
	{
		/// <summary>
		/// 
		/// </summary>
		/// <param name="cl"></param>
		/// <param name="dl"></param>
		/// <returns></returns>
		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		static public byte DecryptPrimitive(byte cl, byte dl)
		{
			return (byte)(~(cl & dl) & (cl | dl));
		}

		/// <summary>
		/// 
		/// </summary>
		static public readonly byte[] Key23 = new byte[] {
			0x23, 0xA0, 0x99, 0x50, 0x3B, 0xA7, 0xB9, 0xB6, 0xE1, 0x8E, 0x92, 0xF9, 0xF4, 0xFC, 0x3D, 0xE8,
			0x71, 0xF9, 0xF4, 0x28, 0xE6, 0xE7, 0xE8, 0x38, 0x33, 0x06, 0x0B, 0x04, 0x0B, 0x03
		};

		static public readonly byte[] Key47 = new byte[] {
			0x47, 0xCE, 0x11, 0x29, 0x3E, 0x8A, 0x8B, 0x84 , 0xD2, 0xD1, 0x62, 0x88, 0x2D, 0xA7, 0x47, 0x19,
			0x08, 0x8A, 0x18, 0x7A, 0xE7, 0x60, 0xE8, 0x08 , 0x37, 0x32, 0x05, 0x0A, 0x48, 0x55
		};

		/*
		static public readonly byte[] Key6E = new byte[] {
			0x6E, 0xF0, 0xEE, 0x98, 0xFF, 0xDB, 0xEB, 0xF2, 0x0A, 0xF2, 0x88, 0x6E, 0x90, 0x81, 0x83, 0xE1,
			0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0x08, 0x21, 0x06, 0x35, 0x30, 0x03, 0x08, 
		};
		*/

		static public readonly byte[] Key82 = new byte[] {
			0x82, 0x74, 0x7D, 0x7D, 0x76, 0x6F, 0x7F, 0x7D, 0x7B, 0x75, 0x28, 0x6F, 0x18, 0x6B, 0x82, 0x00,
			0x65, 0xE4, 0xE4, 0x7B, 0xE6, 0xE7, 0xE8, 0x08, 0x0D, 0x06, 0x35, 0x2B, 0xC3, 0x05,
		};




		/// <summary>
		/// 
		/// </summary>
		/// <param name="data"></param>
		static private void DecryptDataInplaceWithKey(byte[] data, byte[] Key)
		{
			byte bl = 0;
			uint dt = 0;

			for (var n = 0; n < data.Length; n++)
			{
				var keyOffset = ((n + bl) % Key.Length);
				var dataByte = data[n];
				var cryptByte = (byte)(Key[keyOffset] | (bl & dt));

				data[n] = DecryptPrimitive(dataByte, cryptByte);

				if (keyOffset == 0)
				{
					bl = Key[(bl + dt) % Key.Length];
					dt++;
				}
			}
		}

		static public byte[] DecryptDataWithKey(byte[] data, byte[] Key)
		{
			var data2 = new byte[data.Length];
			Array.Copy(data, data2, data.Length);
			DecryptDataInplaceWithKey(data2, Key);
			return data2;
		}

		static public byte[] DecryptData(byte[] data)
		{
			switch (data[0])
			{
				case 0x23: return DecryptDataWithKey(data, Key23);
				case 0x47: return DecryptDataWithKey(data, Key47);
				case 0x82: return DecryptDataWithKey(data, Key82);
				//default: return DecryptDataWithKey(data, Key6E);
				default: throw(new NotImplementedException());
			}
		}
	}
}
