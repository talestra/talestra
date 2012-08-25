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
			var Output = Decrypt.DecryptData(Input);
			CollectionAssert.AreEqual(Expected, Output);
		}
	}
}
