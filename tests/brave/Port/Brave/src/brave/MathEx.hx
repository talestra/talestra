package brave;

/**
 * ...
 * @author 
 */

class MathEx 
{

	public function new() 
	{
		
	}

	static public function _length(x:Float, y:Float):Float {
		return Math.sqrt(x * x + y * y);
	}

	static public function clamp(v:Float, min:Float, max:Float):Float {
		if (v < min) return min;
		if (v > max) return max;
		return v;
	}

	static public function interpolate(v:Float, aMin:Float, aMax:Float, bMin:Float, bMax:Float):Float {
		var aDist:Float = aMax - aMin;
		var bDist:Float = bMax - bMin;
		v = clamp(v, aMin, aMax);
		var v0:Float = (v - aMin) / aDist;
		return (v0 * bDist) + bMin;
	}
}