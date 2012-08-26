using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class CgDb
	{
		public CgDb()
		{
		}

		public enum Type : uint
		{
			Background = 0,
			Image = 1,
			Face = 2,
			Item = 3,
			Objects = 4,
			Tiles = 6,
			Animations = 8,
			Tiles2 = 9,
			Character = 11,
			Animation2 = 13,
			Effect = 15,
		}

		/// <summary>
		/// 
		/// </summary>
		[StructLayout(LayoutKind.Sequential, Pack = 1, Size = 0x28)]
		public struct Entry
		{
			/// <summary>
			/// 
			/// </summary>
			public Type Item;

			/// <summary>
			/// 
			/// </summary>
			public byte Dummy;

			/// <summary>
			/// 
			/// </summary>
			[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 11)]
			public string Name;

			/// <summary>
			/// 
			/// </summary>
			public uint ImageId;

			/// <summary>
			/// 
			/// </summary>
			public int TileWidth;

			/// <summary>
			/// 
			/// </summary>
			public int TileHeight;

			public override string ToString()
			{
				return String.Format("CgDb.Entry(Type={0}, Name='{1}', ImageId=0x{2:X8}, TileSize={3}x{4})", Item, Name, ImageId, TileWidth, TileHeight);
			}
		}

		public Dictionary<string, Entry> Entries;

		public void Load(Stream Stream)
		{
			Entries = new Dictionary<string, Entry>();
			Stream.Position = 8;
			while (Stream.Position < Stream.Length)
			{
				var Entry = Stream.ReadStruct<Entry>();
				if (Entry.ImageId != 0)
				{
					Entries.Add(Entry.Name, Entry);
				}
			}
		}
	}
}
