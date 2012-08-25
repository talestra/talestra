using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class Map
	{
		[StructLayout(LayoutKind.Sequential, Pack = 1, CharSet = CharSet.Ansi)]
		public struct PartEntry
		{
			public uint Unknown;

			[MarshalAs(UnmanagedType.AnsiBStr, SizeConst = 9)]
			public string Name;
		}

		public void Load(Stream Stream)
		{
			var BinaryReader = new BinaryReader(Stream);
			Stream.Position = 8;
		}
	}
}
