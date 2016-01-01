package flash.geom {
	import flash.geom.*;
	
	public class GeometryContainerOptimized extends GeometryContainer {
		// Vector para almacenar las líneas de colisión
		private var olines = {};
		// Vector para almacenar los rectángulos de colisión
		private var orects = {};
		
		public var boxSize = new Point(22, 18);		
				
		private function getLinePoints(line:Line):Array {
			var rpoints = {}, points:Array = [];
			var director:Point = line.getDirector();
			var mult:Number, offset:Number, bi = undefined, cx, cy;
			var p1:Point, p2:Point, ci;

			ci = new Point(Math.floor(line.p1.x / boxSize.x), Math.floor(line.p1.y / boxSize.y)); rpoints[ci] = ci;
			ci = new Point(Math.floor(line.p2.x / boxSize.x), Math.floor(line.p2.y / boxSize.y)); rpoints[ci] = ci;
			
			// Recorremos la línea horizontalmente
			if (Math.abs(director.x) >= Math.abs(director.y)) {
				if (line.p1.x < line.p2.x) { p1 = line.p1; p2 = line.p2; } else { p1 = line.p2; p2 = line.p1; }
				mult = director.y / director.x; offset = p1.y - mult * p1.x;
				// Debug //for (var x = p1.x, x2 = p2.x; x <= x2; x++) { var y = (mult * x + offset); trace(x + ',', y); }				
				//for (var x = Math.floor(p1.x / boxSize.x) + 1, x2 = Math.ceil(p2.x / boxSize.x); x < x2; x++) {
				for (var x = Math.floor(p1.x / boxSize.x), x2 = Math.ceil(p2.x / boxSize.x); x <= x2; x++) {
				//for (var x = Math.floor(p1.x / boxSize.x) + 1, x2 = Math.ceil(p2.x / boxSize.x); x <= x2; x++) {
					cx = x * boxSize.x; cy = Math.floor((mult * cx + offset) / boxSize.y);
					ci = new Point(x - 1, cy); rpoints[ci] = ci;
					ci = new Point(x    , cy); rpoints[ci] = ci;
				}
			}
			// Recorremos la línea verticalmente
			else {
				if (line.p1.y < line.p2.y) { p1 = line.p1; p2 = line.p2; } else { p1 = line.p2; p2 = line.p1; }
				mult = director.x / director.y; offset = p1.x - mult * p1.y;
				//for (var y = Math.floor(p1.y / boxSize.y) + 1, y2 = Math.ceil(p2.y / boxSize.y); y < y2; y++) {
				for (var y = Math.floor(p1.y / boxSize.y), y2 = Math.ceil(p2.y / boxSize.y); y <= y2; y++) {
				//for (var y = Math.floor(p1.y / boxSize.y) + 1, y2 = Math.ceil(p2.y / boxSize.y); y <= y2; y++) {
					cy = y * boxSize.y; cx = Math.floor((mult * cy + offset) / boxSize.x);
					ci = new Point(cx, y - 1); rpoints[ci] = ci;
					ci = new Point(cx, y    ); rpoints[ci] = ci;
				}
			}
			
			// Añadimos los puntos a la lista
			for each (ci in rpoints) points.push(ci);
			
			return points;
		}

		private function getRectPoints(rect:Rectangle):Array {
			var points:Array = [];
			var x1 = Math.floor(rect.left / boxSize.x), x2 = Math.floor(rect.right  / boxSize.x);
			var y1 = Math.floor(rect.top  / boxSize.y), y2 = Math.floor(rect.bottom / boxSize.y);
			for (; y1 <= y2; y1++) for (var x:int = x1; x <= x2; x++) points.push(new Point(x, y1));
			return points;
		}
		
		// Añade una línea
		override public function addLine(line:Line):void {			
			var points:Array = getLinePoints(line);
			// Añade referencias de los puntos a la línea
			//trace(points);
			olines[line] = points;
			// Añade referencias de la línea en los puntos
			for each (var point:Point in points) {
				if (!(point in olines)) olines[point] = [];
				olines[point].push(line);
			}
			lines.push(line);
		}

		// Añade un rectángulo
		override public function addRect(rect:Rectangle):void {
			var points:Array = getRectPoints(rect);
			// Añade referencias de los puntos al rectángulo
			orects[rect] = points;
			// Añade referencias del rectángulo en los puntos
			for each (var point:Point in points) {
				if (!(point in orects)) orects[point] = [];
				orects[point].push(rect);
			}
		}
		
		// Elimina todas las líneas
		override public function removeAllLines():void { olines = {}; lines = []; }

		// Elimina todos los rectángulos
		override public function removeAllRects():void { orects = {}; }
		
		override public function getLines():Array {
			return lines;
		}
		
		override protected function checkLinesCollision(r:Rectangle):Array {
			var clines:Array = [];
			
			// Localizamos las casillas de la rejilla que hemos de examinar
			for each (var boxp:Point in getRectPoints(r)) {				
				for each (var line:Line in olines[boxp]) {
					//trace(line);
					if (Geometry.collisionLineRectangle(line, r)) clines.push(line);
				}
			}
			
			return clines;
		}
	}
}