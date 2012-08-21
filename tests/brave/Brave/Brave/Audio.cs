using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	/// <summary>
	/// RAW PCM - 16 bit signed - Little Endian - 11025 HZ
	/// </summary>
	public class Audio
	{
		public class Entry
		{
			public Audio Audio;
			public string Name;
			public int Length;
			public uint Position;

			public byte[] GetBytes()
			{
				Audio.Stream.Position = Position;
				return (new BinaryReader(Audio.Stream)).ReadBytes(Length);
			}

			public MemoryStream GetWave()
			{
				var Bytes = GetBytes();
				int AudioFormat = 1;
				int NumChannels = Audio.NumberOfChannels;
				int SampleRate = 11025;
				int BitsPerSample = 16;
				int ByteRate = SampleRate * NumChannels * BitsPerSample / 8;
				int BlockAlign = NumChannels * BitsPerSample / 8;
				int NumSamples = Bytes.Length / BlockAlign;

				var OutStream = new MemoryStream();
				var BinaryWriter = new BinaryWriter(OutStream);
				BinaryWriter.Write(Encoding.ASCII.GetBytes("RIFF"));
				BinaryWriter.Write((uint)(36 + Bytes.Length));
				BinaryWriter.Write(Encoding.ASCII.GetBytes("WAVE"));
				BinaryWriter.Write(Encoding.ASCII.GetBytes("fmt "));
				BinaryWriter.Write((uint)(16)); // Subchunk1Size
				BinaryWriter.Write((ushort)(AudioFormat)); // AudioFormat
				BinaryWriter.Write((ushort)(NumChannels));
				BinaryWriter.Write((uint)(SampleRate));
				BinaryWriter.Write((uint)(ByteRate));
				BinaryWriter.Write((ushort)(BlockAlign));
				BinaryWriter.Write((ushort)(BitsPerSample));
				BinaryWriter.Write(Encoding.ASCII.GetBytes("data"));
				BinaryWriter.Write((uint)(Bytes.Length));
				BinaryWriter.Write(Bytes);

				OutStream.Position = 0;
				return OutStream;
			}

			public override string ToString()
			{
				return String.Format("Entry({0}, {1}, {2})", Name, Length, Position);
			}
		}

		private Entry ReadEntry(BinaryReader BinaryReader, uint StartPosition)
		{
			var Entry = new Entry();
			var ShiftJisEncoding = Encoding.GetEncoding("shift_jis");
			var ReadedBytes = BinaryReader.ReadBytes(10);
			int StringzCount = Array.IndexOf(ReadedBytes, (byte)0);
			Entry.Audio = this;
			Entry.Name = ShiftJisEncoding.GetString(ReadedBytes, 0, StringzCount);
			Entry.Length = BinaryReader.ReadInt32();
			Entry.Position = BinaryReader.ReadUInt32() + StartPosition;
			BinaryReader.ReadBytes(6);
			return Entry;
		}

		public List<Entry> Entries = new List<Entry>();
		public Stream Stream;
		public int NumberOfChannels = 1;

		public Audio(int NumberOfChannels = 1)
		{
			this.NumberOfChannels = NumberOfChannels;
		}

		public Audio Load(Stream Stream)
		{
			this.Stream = Stream;

			var BinaryReader = new BinaryReader(Stream);
			BinaryReader.ReadBytes(4);
			var HeaderBlocks = BinaryReader.ReadUInt16();
			var EntryCount = BinaryReader.ReadUInt16();
			BinaryReader.ReadBytes(HeaderBlocks * 20);

			BinaryReader.ReadBytes(2);

			var StartPosition = (uint)(Stream.Position + EntryCount * 24);

			for (int n = 0; n < EntryCount; n++)
			{
				var Entry = ReadEntry(BinaryReader, StartPosition);
				Entries.Add(Entry);
				//Console.WriteLine(Entry);
				//Console.ReadKey();
			}

			return this;
		}
	}
}
