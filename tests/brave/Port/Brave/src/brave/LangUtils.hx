package brave;

/**
 * ...
 * @author 
 */

class LangUtils 
{

	public function new() 
	{
		
	}

	public static function createArray<T>(init:Void->T, len:Int):Array<T> { 
        var ret = new Array<T>(); 
        for (n in 0 ... len) ret.push(init());
        return ret; 
    } 

	public static function createArray2D<T>(init:Void->T, w:Int, ?h:Int):Array<Array<T>> { 
        if (h == null) h = w; 
        var ret = []; 
        for (i in 0...w) { 
            var row = []; 
            for (j in 0...h) 
                row.push(init()); 
            ret.push(row); 
        } 
        return ret; 
    } 
}