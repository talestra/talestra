package brave;
import haxe.Log;
import haxe.PosInfos;

/**
 * ...
 * @author 
 */

class BraveLog 
{
	public static dynamic function trace( v : Dynamic, ?infos : PosInfos ) : Void {
		#if !flash
			Log.trace( v, infos );
		#end
	}

	public static dynamic function setColor( rgb: Int ) : Void {
		#if flash
			Log.setColor(rgb);
		#end
	}
}