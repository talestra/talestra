package flash.geom {
	import flash.geom.Point;
	
	public class Line {
		public var p1:Point;
		public var p2:Point;
		
		public function Line(p1:Point, p2:Point) {
			this.p1 = p1;
			this.p2 = p2;
		}
		
		public function getDirector():Point {
			return p2.subtract(p1);
		}
		
		public function get size():Point {
			return p2.subtract(p1);
		}

		public function get width():Number {
			return p2.subtract(p1).x;
		}

		public function get height():Number {
			return p2.subtract(p1).y;
		}

		public function get length():Number {
			return p2.subtract(p1).length;
		}
	}
}