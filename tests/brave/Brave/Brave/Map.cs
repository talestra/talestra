using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class Map
	{
		static private string ReadStringz(BinaryReader BinaryReader)
		{
			byte Byte = 0;
			var MemoryStream = new MemoryStream();
			while ((Byte = BinaryReader.ReadByte()) > 0) MemoryStream.WriteByte(Byte);
			return Encoding.ASCII.GetString(MemoryStream.ToArray());
		}

		private Part ReadEntry(BinaryReader BinaryReader)
		{
			int PartId = BinaryReader.ReadInt32();
			string Name = "";
			if (PartId >= 0)
			{
				Name = ReadStringz(BinaryReader);
			}
#if false
			Console.WriteLine("{0:X8} : {1}", PartId, Name);
#endif
			return new Part()
			{
				PartId = PartId,
				Name = Name,
			};
		}

		private void CreateMap(byte Unk, int Width, int Height)
		{
			Console.WriteLine("{0}x{1}", Width, Height);
		}

		public class Part
		{
			public int PartId;
			public string Name;
			public Bitmap Bitmap;
		}

		public struct CellLayer
		{
			public Part Part;
			public int X;
			public int Y;

			public CellLayer(Part Entry, int X, int Y)
			{
				this.Part = Entry;
				this.X = X;
				this.Y = Y;
			}
		}

		public struct Cell
		{
			public CellLayer BackgroundLayer;
			public CellLayer ObjectLayer;
			public int V0;
			public int V1;
			public byte Info;
			public byte V3;
		}

		public string PartsPath;
		public int Unk1, Unk2;
		public int Width, Height;
		public Dictionary<int, Part> Parts = new Dictionary<int, Part>();
		public Cell[,] Cells;

		public Map(string PartsPath)
		{
			this.PartsPath = PartsPath;
		}

		public Bitmap Render()
		{
			var Bitmap = new Bitmap(Width * 40, Height * 40);
			var BitmapGraphics = Graphics.FromImage(Bitmap);

			for (int y = 0; y < Height; y++)
			{
				for (int x = 0; x < Width; x++)
				{
					var Cell = Cells[x, y];
					var Layer = Cell.BackgroundLayer;
					var Part = Layer.Part;
					if (Part != null)
					{
						var TilesImage = Part.Bitmap;
						var DestinationPoint = new Point(x * 40, y * 40);
						
						BitmapGraphics.DrawImage(TilesImage, DestinationPoint.X, DestinationPoint.Y, new Rectangle(Layer.X, Layer.Y, 40, 40), GraphicsUnit.Pixel);
					}
				}
			}

			for (int y = 0; y < Height; y++)
			{
				for (int x = 0; x < Width; x++)
				{
					var Cell = Cells[x, y];
					var Layer = Cell.ObjectLayer;
					var Part = Layer.Part;
					if (Part != null)
					{
						var TilesImage = Part.Bitmap;
						int TileW = 40;
						int TileH = 0;

						switch (Cell.Info)
						{
							// Sure
							case 0xDE: TileH = 40; break;
							// Sure
							case 0x8F: TileH = 80; break;
							// SURE
							case 0x10: TileH = 40; break;
							// SURE
							case 0xCF: TileH = 80; break;

							// SURE
							case 0x01: TileH = 160; break;

							// ???
							case 0xFF: TileH = 80; break;
							case 0x00: TileH = 40; break;

							//case 0xFF: TileH = 160; break;
							//case 0x00: TileH = 160; break;

							//case 0xFF: TileH = TilesImage.Height; break;
							//case 0x00: TileH = TilesImage.Height; break;

							case 0x20: TileH = 120; break;
							case 0x18: 
							case 0x17: 
							case 0x87: 
							case 0x5E: 
							case 0x5C: 
							case 0x08: 
							case 0x07: 
							case 0x3E: 
							case 0x1F: 
							case 0x58: 
							case 0x0F: 
							case 0x1E:
								TileH = 40;
								Console.WriteLine("V2: ({0},{1}) : ({2},{3}) : {4:X2}", x, y, x * 40, y * 40, Cell.Info);
								Console.WriteLine(" ---> {0} : ({1},{2})", Layer.Part.Name, Layer.X, Layer.Y);
								Console.WriteLine(" ---> {0},{1},{2},{3}", Cell.V0, Cell.V1, Cell.Info, Cell.V3);
								break;
							default:
								Console.WriteLine("{0:X2}", Cell.Info);
								throw(new NotImplementedException());
						}

						if (TileH == 40)
						{
							Console.WriteLine("V2: ({0},{1}) : ({2},{3}) : {4:X2}", x, y, x * 40, y * 40, Cell.Info);
							Console.WriteLine(" ---> {0} : ({1},{2})", Layer.Part.Name, Layer.X, Layer.Y);
							Console.WriteLine(" ---> {0},{1},{2},{3}", Cell.V0, Cell.V1, Cell.Info, Cell.V3);
						}

						//TileH = TilesImage.Height;
						/*
						if (Cell.LayerBHeight == 0xFF)
						{
							
						}
						else
						{
							TileH = Cell.LayerBHeight;
						}
						*/

						var DestinationPoint = new Point(x * 40, y * 40 + 40 - TileH);
						BitmapGraphics.DrawImage(TilesImage, DestinationPoint.X, DestinationPoint.Y, new Rectangle(Layer.X, Layer.Y, TileW, TileH), GraphicsUnit.Pixel);
					}
				}
			}

#if false
			for (int y = 0; y < Height; y++)
			{
				for (int x = 0; x < Width; x++)
				{
					var Cell = Cells[x, y];
					Console.WriteLine("({0}, {1}), ({2}, {3})", Cell.V0, Cell.V1, Cell.V2, Cell.V3);
				}
			}
#endif

			return Bitmap;
		}

		public void Load(Stream Stream)
		{
			var BinaryReader = new BinaryReader(Stream);
			
			Stream.Position = 8;

			for (int n = 0; n < 32; n++)
			{
				var Part = ReadEntry(BinaryReader);
				if (Part.PartId >= 0)
				{
					Part.Bitmap = BraveImage.DecodeImage(File.OpenRead(String.Format(@"{0}\{1}.CRP", PartsPath, Part.Name)));
				}
				Parts[Part.PartId] = Part;
			}

			if (BinaryReader.ReadInt32() != -1)
			{
				throw(new NotImplementedException());
			}

			Unk1 = BinaryReader.ReadByte();
			Width = (int)BinaryReader.ReadInt16();
			Height = (int)BinaryReader.ReadInt16();

			Cells = new Cell[Width, Height];

			BinaryReader.ReadUInt32();

			for (int y = 0; y < Height; y++)
			{
				//Console.WriteLine("----------------");
				for (int x = 0; x < Width; x++)
				{
					int V0 = BinaryReader.ReadSByte();
					if (V0 != -1)
					{
						var PartId = BinaryReader.ReadSByte();
						int ImageX = BinaryReader.ReadInt16();
						int ImageY = BinaryReader.ReadInt16();
						//Console.WriteLine("A:{0:X8} : {1}, {2}", PartId, ImageX, ImageY);
						Cells[x, y].BackgroundLayer = new CellLayer(Parts[PartId], ImageX, ImageY);
					}

					int V1 = BinaryReader.ReadSByte();
					if (V1 != -1) // FAKE! It checks memory (0042E1D3)
					{
						var PartId = BinaryReader.ReadSByte();
						int ImageX = BinaryReader.ReadInt16();
						int ImageY = BinaryReader.ReadInt16();
						//Console.WriteLine("B:{0:X8} : {1}, {2}", PartId, ImageX, ImageY);
						Cells[x, y].ObjectLayer = new CellLayer(Parts[PartId], ImageX, ImageY);
					}

					var V2 = BinaryReader.ReadByte();
					var V3 = BinaryReader.ReadByte();

					Cells[x, y].V0 = V0;
					Cells[x, y].V1 = V1;
					Cells[x, y].Info = V2;
					Cells[x, y].V3 = V3;

					//if (V2 != 0xFF && V2 != 0x00)
#if false
					var ObjectLayer = Cells[x, y].ObjectLayer;
					if (ObjectLayer.Part != null)
					{
						//if (V2 != 0x00)
						{
							Console.WriteLine("V2: ({0},{1}) : ({2},{3}) : {4}", x, y, x * 40, y * 40, V2);
							if (ObjectLayer.Part != null)
							{
								Console.WriteLine(" ---> {0} : ({1},{2})", ObjectLayer.Part.Name, ObjectLayer.X, ObjectLayer.Y);
								Console.WriteLine(" ---> {0},{1},{2},{3}", V0, V1, V2, V3);
							}
						}
					}
					//Console.WriteLine("{0}, {1}", V2, V3);
#endif
				}
			}

			Unk2 = (int)BinaryReader.ReadInt32();

			//Console.WriteLine(Stream.Position);
		}
	}
}
