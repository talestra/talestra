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

#if true
			Console.WriteLine("Script...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\scenario", "*.dat"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".scr";
				var Bytes = File.ReadAllBytes(FileIn);
				if (!File.Exists(FileOut))
				{
					Decrypt.DecryptDataInplace(Bytes);
					File.WriteAllBytes(FileOut, Bytes);
					Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				}
			}

			Console.WriteLine("Base...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\", "*.dat"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".scr";
				var Bytes = File.ReadAllBytes(FileIn);
				if (!File.Exists(FileOut))
				{
					Decrypt.DecryptDataInplace(Bytes);
					File.WriteAllBytes(FileOut, Bytes);
					Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				}
			}

			Console.WriteLine("Maps...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\map", "*.dat"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".map";
				Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				if (!File.Exists(FileOut))
				{
					var Bytes = File.ReadAllBytes(FileIn);
					Decrypt.DecryptDataInplace(Bytes);
					File.WriteAllBytes(FileOut, Bytes);
				}
			}

			Console.WriteLine("Images...");
			foreach (var FileIn in Directory.EnumerateFiles(GameDirectory + @"\parts", "*.crp"))
			{
				var FileOut = Path.GetDirectoryName(FileIn) + @"\" + Path.GetFileNameWithoutExtension(FileIn) + ".png";
				Console.WriteLine("{0} -> {1}", FileIn, FileOut);
				if (!File.Exists(FileOut))
				{
					BraveImage.DecodeImage(File.OpenRead(FileIn)).Save(FileOut);
				}
			}
#endif
		}
	}
}
