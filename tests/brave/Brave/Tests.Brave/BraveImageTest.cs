using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using Brave;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tests.Brave
{
	[TestClass]
	public class BraveImageTest
	{
		static private byte[] BitmapToByteArray(Bitmap Bitmap)
		{
			var Output = new MemoryStream();
			Bitmap.Save(Output, ImageFormat.Bmp);
			return Output.ToArray();
		}

		[TestMethod]
		public void TestDecodeImage()
		{
			var Expected = new Bitmap(Image.FromFile(TestUtils.TestInput + @"\C_VA.png.expected"));
			var Result = BraveImage.DecodeImage(File.OpenRead(TestUtils.TestInput + @"\C_VA.CRP"));
			CollectionAssert.AreEqual(BitmapToByteArray(Expected), BitmapToByteArray(Result));
		}
	}
}
