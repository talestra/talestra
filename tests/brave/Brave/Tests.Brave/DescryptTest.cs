using System;
using System.IO;
using Brave;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tests.Brave
{
	[TestClass]
	public class DescryptTest
	{
		[TestMethod]
		public void TestDecryptData()
		{
			var Input = File.ReadAllBytes(TestUtils.TestInput + @"\op.dat");
			var Expected = File.ReadAllBytes(TestUtils.TestInput + @"\op.scr.expected");
			var Output = Decrypt.DecryptDataWithKey(Input, Decrypt.Key23);
			File.WriteAllBytes(TestUtils.TestOutput + @"\op.scr.c", Decrypt.DecryptDataWithKey(File.ReadAllBytes(TestUtils.TestOutput + @"\op.txt"), Decrypt.Key23));
			CollectionAssert.AreEqual(Expected, Output);
		}
	}
}
