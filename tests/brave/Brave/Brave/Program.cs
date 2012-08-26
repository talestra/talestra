using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	class Program
	{
		static void Main(string[] args)
		{
			var GameDirectory = @"C:\Juegos\brave_s";

			if (args.Length == 0)
			{
				Console.Error.WriteLine("Must specify the game path");
			}
			else
			{
				GameDirectory = args[0];
			}

			var PartsDirectory = GameDirectory + @"\parts";

			Console.WriteLine("Images...");
			foreach (var FileIn in Directory.EnumerateFiles(PartsDirectory, "*.crp"))
			{
				//var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".png";
				var FileOutU = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".crp.u";
				var FileOutPng = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".png";
				Console.WriteLine("{0} -> {1}", FileIn, FileOutPng);
				if (!File.Exists(FileOutU))
				{
					File.WriteAllBytes(FileOutU, Lz.DecodeStream(File.OpenRead(FileIn)));
				}
				if (!File.Exists(FileOutPng))
				{
					BraveImage.DecodeImage(File.OpenRead(FileIn)).Save(FileOutPng);
				}
			}

#if true
			Console.WriteLine("Script...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\scenario", "*.dat"))
			{
				var FileOutU = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".scr";
				var FileOutAsm = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".asm";
				Console.WriteLine("{0}...", FileIn);
				
				if (!File.Exists(FileOutU))
				{
					var Bytes = File.ReadAllBytes(FileIn);
					var BytesOut = Decrypt.DecryptDataWithKey(Bytes, Decrypt.Key23);
					File.WriteAllBytes(FileOutU, BytesOut);
					Console.WriteLine("{0} -> {1}", FileIn, FileOutU);
				}
				
				if (!File.Exists(FileOutAsm))
				{
					var Script = new Script(new MemoryStream(Decrypt.DecryptDataWithKey(File.ReadAllBytes(FileIn), Decrypt.Key23)));
					File.WriteAllLines(FileOutAsm, Script.ParseAll().Select(Item => Item.ToString()));
				}
			}

			Console.WriteLine("Base...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\", "*.dat"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".scr";
				var Bytes = File.ReadAllBytes(FileIn);
				if (!File.Exists(FileOut))
				{
					var BytesOut = Decrypt.DecryptData(Bytes);
					File.WriteAllBytes(FileOut, BytesOut);
					Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				}
			}

			Console.WriteLine("Saves...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\save", "*.sav"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".sav.u";
				var Bytes = File.ReadAllBytes(FileIn);
				if (!File.Exists(FileOut))
				{
					var BytesOut = Decrypt.DecryptData(Bytes);
					File.WriteAllBytes(FileOut, BytesOut);
					Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				}
			}

			Console.WriteLine("Maps...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\map", "*.dat"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".map";
				var FileOutPng = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".png";
				Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				if (!File.Exists(FileOut))
				{
					var Bytes = File.ReadAllBytes(FileIn);
					var BytesOut = Decrypt.DecryptData(Bytes);
					File.WriteAllBytes(FileOut, BytesOut);
				}
				if (!File.Exists(FileOutPng))
				{
					var Map = new Map(PartsDirectory, GameDirectory + @"\cgdb.dat");
					Map.Load(new MemoryStream(File.ReadAllBytes(FileOut)));
					Map.Render().Save(FileOutPng);
				}
			}

			Console.WriteLine("Sound...");
			{
				try { Directory.CreateDirectory(GameDirectory + @"\sound"); }
				catch { }
				var Audio = (new Audio(NumberOfChannels: 2)).Load(File.OpenRead(GameDirectory + @"\sound.pck"));
				foreach (var Entry in Audio.Entries)
				{
					var FileOut = String.Format(@"{0}\sound\{1}.wav", GameDirectory, Entry.Name);
					Console.WriteLine("{0}", FileOut);
					if (!File.Exists(FileOut))
					{
						File.WriteAllBytes(FileOut, Entry.GetWave().ToArray());
					}
				}
			}

			Console.WriteLine("Voices...");
			{
				var Audio = (new Audio(NumberOfChannels: 1)).Load(File.OpenRead(GameDirectory + @"\voice\voice.pck"));
				foreach (var Entry in Audio.Entries)
				{
					var FileOut = String.Format(@"{0}\voice\{1}.wav", GameDirectory, Entry.Name);
					Console.WriteLine("{0}", FileOut);
					if (!File.Exists(FileOut))
					{
						File.WriteAllBytes(FileOut, Entry.GetWave().ToArray());
					}
				}
			}
#endif
		}
	}
}
