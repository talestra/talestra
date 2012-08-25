using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace Brave
{
	public class BraveImage
	{
		/// <summary>
		/// 
		/// </summary>
		static private readonly byte[] DecodeImageKey = new byte[] {
			0x84, 0x41, 0xDE, 0x48, 0x08, 0xCF, 0xCF, 0x6F, 0x62, 0x51, 0x64, 0xDF, 0x41, 0xDF, 0xE2, 0xE1
		};

		/// <summary>
		/// 
		/// </summary>
		/// <param name="_Stream"></param>
		/// <returns></returns>
		unsafe static public Bitmap DecodeImage(Stream _Stream)
		{
			var Stream = new MemoryStream(Lz.DecodeStream(_Stream));
			var BinaryReader = new BinaryReader(Stream);

			var Magic = BinaryReader.ReadBytes(14);

			if (Encoding.ASCII.GetString(Magic) != "(C)CROWD ARPG\0") throw (new InvalidDataException("Invalid file"));

			var Key = BinaryReader.ReadBytes(8);
			var Header = BinaryReader.ReadBytes(16);

			// STEP1
			for (int n = 0; n < 0x10; n++)
			{
				Header[n] = Decrypt.DecryptPrimitive(DecodeImageKey[n], Header[n]);
			}

			//printf("----------------\n");

			// STEP2
			for (int n = 0; n < 0x10; n++)
			{
				Header[n] = Decrypt.DecryptPrimitive(Header[n], Key[n % 8]);
			}

			var HeaderReader = new BinaryReader(new MemoryStream(Header));

			var Width = HeaderReader.ReadInt32();
			var Height = HeaderReader.ReadInt32();
			var Skip = HeaderReader.ReadInt32();

			Stream.Seek(Skip, SeekOrigin.Current);

			var Image = new Bitmap(Width, Height);
			//var ImageData = BinaryReader.ReadBytes(Width * Height * 2);


			var EncodedData = BinaryReader.ReadBytes(Width * Height * 2);

			fixed (byte* _EncodedDataPtr = EncodedData)
			{
				var EncodedDataPtr = (ushort*)_EncodedDataPtr;
				var BitmapData = Image.LockBits(new Rectangle(0, 0, Width, Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
				var Base = (byte*)BitmapData.Scan0;

				for (int y = 0; y < Height; y++)
				{
					var Ptr = &Base[BitmapData.Stride * y];

					for (int x = 0; x < Width; x++)
					{
						var PixelData = *EncodedDataPtr++;
						var b = (byte)ExtractScale(PixelData, 0, 5, 0xff);
						var g = (byte)ExtractScale(PixelData, 5, 6, 0xff);
						var r = (byte)ExtractScale(PixelData, 11, 5, 0xff);
						
						//ff00ff

						// FUCSIA -> Transparent
						if ((r == 0xFF) && (b == 0xFF))
						{
							Ptr[0] = 0;
							Ptr[1] = 0;
							Ptr[2] = 0;
							Ptr[3] = 0x00;
						}
						else
						{
							Ptr[0] = b;
							Ptr[1] = g;
							Ptr[2] = r;
							Ptr[3] = 0xFF;
						}

						Ptr += 4;
						//Image.SetPixel(x, y, Color.FromArgb(0xFF, r, g, b));
					}
				}

				Image.UnlockBits(BitmapData);
			}

			return Image;
		}

		/// <summary>
		/// 
		/// </summary>
		/// <param name="v"></param>
		/// <param name="offset"></param>
		/// <param name="count"></param>
		/// <param name="to"></param>
		/// <returns></returns>
		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		static private int ExtractScale(int v, int offset, int count, int to)
		{
			var mask = ((1 << count) - 1);
			return (((v >> offset) & mask) * to) / mask;
		}
	}
}
