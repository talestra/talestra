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
		static private readonly byte[] DecryptDataInplaceKey = new byte[] {
			0x23, 0xA0, 0x99, 0x50, 0x3B, 0xA7, 0xB9, 0xB6, 0xE1, 0x8E, 0x92, 0xF9,
			0xF4, 0xFC, 0x3D, 0xE8, 0x71, 0xF9, 0xF4, 0x28, 0xE6, 0xE7, 0xE8, 0x38,
			0x33, 0x06, 0x0B, 0x04, 0x0B, 0x03
		};

		/// <summary>
		/// 
		/// </summary>
		/// <param name="data"></param>
		static public void DecryptDataInplace(byte[] data)
		{
			byte bl = 0;
			byte dt = 0;

			for (var n = 0; n < data.Length; n++)
			{
				var keyOffset = ((n + bl) % DecryptDataInplaceKey.Length);
				var dataByte  = data[n];
				var cryptByte = (byte)(DecryptDataInplaceKey[keyOffset] | (bl & dt));

				data[n] = DecryptPrimitive(dataByte, cryptByte);
		
				if (keyOffset == 0) {

					bl = DecryptDataInplaceKey[(bl + dt) % DecryptDataInplaceKey.Length];
					dt++;
				}
			}
		}


	}
}
