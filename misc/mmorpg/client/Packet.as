package {
	import flash.utils.Endian;
	import flash.utils.ByteArray;
	import flash.geom.Point;
	
	dynamic public class Packet extends ByteArray {
		public var id;
		
		// Constructor
		public function Packet(id) {
			this.id = id;
			this.endian = Endian.LITTLE_ENDIAN;
			super();
			//var ba:ByteArray = new ByteArray();
		}
		
		// Como flash no tiene enteros de 64 bits, tenemos que usar
		// Number (doubles), con una precisión de enteros de un máximo de
		// 53 bits.
		
		public function readLong():Number {
			var low  = readUnsignedInt();
			var high = readInt();
			return (low + Math.abs(high) * 0x100000000) * ((high < 0) ? -1 : 1);
		}
		
		public function writeLong(value:Number):void {
			writeUnsignedInt(Math.abs(value) % 0x100000000);
			writeInt(value / 0x100000000);
		}
		
		public function readBytePoint():Point {
			var x = readByte();
			var y = readByte();
			return new Point(x, y);
		}
		
		public function writeBytePoint(value:Point):void {
			writeByte(value.x);
			writeByte(value.y);
		}

		public function readIntPoint():Point {
			var x = readInt();
			var y = readInt();
			return new Point(x, y);
		}
		
		public function writeIntPoint(value:Point):void {
			writeInt(value.x);
			writeInt(value.y);
		}

		public function readFloatPoint():Point {
			var x = readFloat();
			var y = readFloat();
			return new Point(x, y);
		}
		
		public function writeFloatPoint(value:Point):void {
			writeFloat(value.x);
			writeFloat(value.y);
		}

		public function readDoublePoint():Point {
			var x = readDouble();
			var y = readDouble();
			return new Point(x, y);
		}
		
		public function writeDoublePoint(value:Point):void {
			writeDouble(value.x);
			writeDouble(value.y);
		}
		
		override public function toString():String {
			return id + '(' + length + ')';
		}
		
		// Listado de paquetes
		
		static public var LOGIN  = 0x00;
		static public var LOGOUT = 0x01;
		static public var INFO   = 0x02;

		static public var CREATE = 0x10;
		static public var REMOVE = 0x11;

		static public var CHAT   = 0x20;

		static public var MOVING = 0x30;

		static public var PING   = 0xFF;
	}
}