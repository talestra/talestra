package {
	import flash.geom.Point;
	
	class Spline {
		private var A:Array = [];
		private var B:Array = [];
		private var C:Array = [];
		public var points:Array = [];

		// Constructor
		public function Spline(points:Array) {
			this.points = points;
			recalc();
		}

		// Recalcula el spline con una nube de puntos
		public function recalc() {
			var h:Array = [];
			var z:Array = [];
			var b:Array = [];
			var v:Array = [];
			var u:Array = [];			
			var i:int;
			
			points = points.sortOn('x', Array.NUMERIC);
			
			for (i = 0; i < points.length - 1; i++) {
				var p1:Point = Point(points[i]), p2:Point = Point(points[i + 1]);
				h[i] = (p2.x - p1.x);
				b[i] = (6 * (p2.y - p1.y) / h[i]);
			}
			
			u[1] = 2 * (h[1] + h[0]);
			v[1] = b[1] - b[0];
			
			for (i = 2; i < points.length - 1; i++) {
				u[i] = 2 * (h[i] - h[i - 1]) - Math.pow(h[i - 1], 2) / u[i - 1];
				v[i] = b[i] - b[i - 1] - h[i - 1] * v[i - 1] / u[i - 1];
			}
			
			z[points.length - 1] = 0;
			for (i = points.length - 2; i >= 1; i--) {
				z[i] = (v[i] - h[i] * z[i + 1]) / u[i];
			}
			z[0] = 0;
						
			for (i = 0; i < points.length - 1; i++) {
				var z0 = z[i], z1 = z[i + 1];
				A[i] = (z1 - z0) / (6 * h[i]);
				B[i] = z0 / 2;
				C[i] = -((h[i] * z1) / 6) - ((h[i] * z0) / 3) + ((points[i + 1].y - points[i].y) / h[i]);
			}			
		}
		
		// Localiza el índice del segmento al que pertenece un punto
		public function LocateIndex(x:Number) {
			var i1:int = 0, i2:int = points.length - 2;
			if (i2 < i1) return 0;
			while (i1 != i2) {
				var i:int = (i2 + i1) / 2;
				var cx = points[i].x;
				
				if (x < points[i].x) {
					i2 = i;
				} else {
					if (x <= points[i + 1].x) return i;
					i1 = i + 1;
				}
			}
			return i1;
		}
		
		// Obtiene el valor de la función en un punto
		public function Get(x:Number) {
			if (points.length == 0) return 0;
			if (points.length == 1) return points[0].y;
			if (x <= points[0].x) return points[0].y;
			if (x >= points[points.length - 1].x) return points[points.length - 1].y;
			var i:int = LocateIndex(x);
			var p:Point = points[i];
			var rx = x - p.x;			
			return p.y + rx * (C[i] + rx * (B[i] + rx * A[i]));
		}
	}
}