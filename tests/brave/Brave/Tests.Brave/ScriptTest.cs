using System;
using System.IO;
using Brave;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tests.Brave
{
	[TestClass]
	public class ScriptTest
	{
		[TestMethod]
		public void TestParseScript()
		{
			var Script = new Script(File.OpenRead(TestUtils.TestInput + @"\op.scr.expected"));
			Script.ParseAll();
		}
	}
}
