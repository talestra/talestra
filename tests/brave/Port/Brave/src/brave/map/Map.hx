package brave.map;
import brave.BraveAssets;
import brave.ByteArrayUtils;
import brave.formats.Decrypt;
import brave.LangUtils;
import haxe.Log;
import nme.display.Graphics;
import nme.errors.Error;
import nme.utils.ByteArray;
import nme.utils.Endian;

/**
 * ...
 * @author 
 */

class Map 
{
	public var width:Int;
	public var height:Int;
	private var tilesets:IntHash<Tileset>;
	private var cells:Array<Array<Cell>>;

	private function new(width:Int, height:Int, ?tilesets:IntHash<Tileset>) 
	{
		this.width = width;
		this.height = height;
		this.cells = LangUtils.createArray2D(function() { return new Cell(null, null, 0, 0); } , width, height);
		if (tilesets == null) tilesets = new IntHash<Tileset>();
		this.tilesets = tilesets;
	}
	
	public function get(x:Int, y:Int):Cell {
		if ((x < 0) || (y < 0) || (x >= width) || (y >= height)) return null;
		return cells[x][y];
	}
	public function getTileset(id:Int):Tileset {
		var tileset:Tileset = tilesets.get(id);
		if (tileset == null) throw(new Error(Std.format("Can't get tileset with id $id")));
		return tileset;
	}
	
	public function drawTo(graphics:Graphics, drawX:Int, drawY:Int, tileX:Int, tileY:Int, tileW:Int, tileH:Int):Void {
		// Draw background
		for (layer in 0 ... 2) {
			drawLayerTo(graphics, layer, drawX, drawY, tileX, tileY, tileW, tileH);
		}
	}

	public function drawLayerTo(graphics:Graphics, layer:Int, drawX:Int, drawY:Int, tileX:Int, tileY:Int, tileW:Int, tileH:Int):Void {
		for (y in 0 ... tileH) {
			for (x in 0 ... tileW) {
				var cell:Cell = get(x + tileX, y + tileY);
				if (cell != null) {
					var layer = (layer == 0) ? cell.layerBackground : cell.layerObject;
					if (layer != null) {
						layer.drawTo(graphics, x * 40 + drawX, y * 40 + drawY);
					}
				}
			}
		}
	}

	static public function loadFromNameAsync(name:String, done:Map -> Void):Void {
		BraveAssets.getBytesAsync(Std.format("map/$name.dat"), function(bytes:ByteArray) {
			loadFromByteArrayAsync(Decrypt.decryptDataWithKey(bytes, Decrypt.key23), done);
		});
	}

	static public function loadFromByteArrayAsync(data:ByteArray, done:Map -> Void):Void {
		
		var tilesets:IntHash<Tileset> = new IntHash<Tileset>();

		function readTilesets() {
			// Read tilesets
			for (n in 0 ... 32) {
				var id:Int = data.readInt();
				if (id >= 0) {
					var name:String = ByteArrayUtils.readStringz(data);
					tilesets.set(id, new Tileset(id, name));
					//BraveLog.trace(name);
				}
			}
		}
		
		function readContent() {
			if (data.readInt() != -1) throw(new Error());
			
			data.readByte();
			var width:Int = data.readUnsignedShort();
			var height:Int = data.readUnsignedShort();
			
			//BraveLog.trace(Std.format("$width,$height"));
			
			var map:Map = new Map(width, height, tilesets);
			
			data.readInt();
			
			for (y in 0 ... height) {
				for (x in 0 ... width) {
					var cell:Cell = map.get(x, y);
					
					if (cell == null) throw(new Error(Std.format("Can't get cell at ($x, $y) - MapSize($width, $height)")));
					
					//if (y > 70) BraveLog.trace(Std.format("$x,$y : ${data.bytesAvailable}"));
					
					if (data.readUnsignedByte() != 0xFF)
					{
						var tilesetId = data.readUnsignedByte();
						var sx = data.readUnsignedShort();
						var sy = data.readUnsignedShort();
						cell.layerBackground = new CellLayer(map.getTileset(tilesetId), sx, sy);
					}

					if (data.readUnsignedByte() != 0xFF)
					{
						var tilesetId = data.readUnsignedByte();
						var sx = data.readUnsignedShort();
						var sy = data.readUnsignedShort();
						cell.layerObject = new CellLayer(map.getTileset(tilesetId), sx, sy);
					}

					cell.info1 = data.readUnsignedByte();
					cell.info2 = data.readUnsignedByte();
				}
			}
			
			//data.readInt();
			
			done(map);
		}
		
		data.endian = Endian.LITTLE_ENDIAN;
		data.position = 8;
		
		readTilesets();
		
		var tilesCount = 0;
		for (tileset in tilesets.iterator()) tilesCount++;
		for (tileset in tilesets.iterator()) {
			tileset.loadDataAsync(function() {
				tilesCount--;
				if (tilesCount == 0) readContent();
			});
		}

	}

	static public function create(width:Int, height:Int):Map {
		return new Map(width, height);
	}
}