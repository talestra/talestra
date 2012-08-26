using System;
using System.IO;
using Brave;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tests.Brave
{
	[TestClass]
	public class CgDbTest
	{
		[TestMethod]
		public void TestCgDbLoad()
		{
			var CgDb = new CgDb();
			CgDb.Load(new MemoryStream(Decrypt.DecryptData(File.ReadAllBytes(TestUtils.TestInput + @"\cgdb.dat"))));
			foreach (var Entry in CgDb.Entries.Values)
			{
				Console.WriteLine(Entry);
			}
		}
	}
}
