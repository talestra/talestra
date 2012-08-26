using System;
using System.IO;
using Brave;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tests.Brave
{
	[TestClass]
	public class MapTest
	{
		[TestMethod]
		public void TestMapLoad()
		{
			var Map = new Map(@"C:\Juegos\brave_s\parts", TestUtils.TestInput + @"\cgdb.dat");
			//Map.Load(new MemoryStream(File.ReadAllBytes(TestUtils.TestInput + @"\b_town2.map")));
			//Map.Load(new MemoryStream(File.ReadAllBytes(TestUtils.TestInput + @"\a_wood0.map")));
			Map.Load(new MemoryStream(File.ReadAllBytes(TestUtils.TestInput + @"\s_room0.map")));
			//Map.Load(new MemoryStream(File.ReadAllBytes(TestUtils.TestInput + @"\a_even0.map")));
			var Img = Map.Render();
			Img.Save(TestUtils.TestOutput + @"\test.png");
			//Map.Load(File.OpenRead(TestUtils.TestInput + @"\a_base1.map"));
		}
	}
}
