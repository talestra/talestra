package brave.map;

/**
 * ...
 * @author 
 */

class Cell 
{
	public var layerBackground:CellLayer;
	public var layerObject:CellLayer;
	public var info1:Int;
	public var info2:Int;

	public function new(layerBackground:CellLayer, layerObject:CellLayer, info1:Int, info2:Int) 
	{
		this.layerBackground = layerBackground;
		this.layerObject = layerObject;
		this.info1 = info1;
		this.info2 = info2;
	}
	
}
