package brave;

/**
 * ...
 * @author 
 */

class StringEx 
{
	static inline var parts:String = "0123456789ABCDEF";
		
	static public function intToString(value:Int, radix:Int):String {
		if (value < 0) return "-" + intToString(-value, radix);
		if (value == 0) return "0";

		var out:String = "";
		while (value != 0) {
			var digit:Int = Std.int(value % radix);
			out = parts.charAt(digit) + out;
			value = Std.int(value / radix);
		}

		return out;
	}

	static public function sprintf(format:String, params: Array<Dynamic>):String {
		var reg:EReg = ~/%(-)?(0)?(\d*)(d|x|s)/g;
		var f:EReg;
		
		return reg.customReplace(format, function (f:EReg):String {
			var minus:String = f.matched(1);
			var zero:String = f.matched(2);
			var numbers:String = f.matched(3);
			var type:String = f.matched(4);
			var direction:Int = 1;
			var padChar:String = ' ';
			var padCount:Int = Std.parseInt(numbers);
			var out:String = "";
			if (minus != null) direction = -1;
			if (zero != null) padChar = zero;
			switch (type) {
				case 'd': out = intToString(params.shift(), 10);
				case 'x': out = intToString(params.shift(), 16).toLowerCase();
				case 'X': out = intToString(params.shift(), 16).toUpperCase();
				case 's': out = params.shift();
			}
			if (direction > 0) {
				out = StringTools.lpad(out, padChar, padCount);
			} else {
				out = StringTools.rpad(out, padChar, padCount);
			}
			//Log.trace(Std.format("$minus, $zero, $numbers, $format"));
			return out;
		});
	}

}