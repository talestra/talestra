package flash.geom {
	import flash.geom.*;
	
	public class GeometryContainer {
		// Vector para almacenar las líneas de colisión
		var lines = [];
		// Vector para almacenar los rectángulos de colisión
		var rects = [];
		
		public function getLines():Array {
			return lines;
		}

		// Añade una línea
		public function addLine(line:Line):void {
			lines.push(line);
		}

		// Añade un rectángulo
		public function addRect(rect:Rectangle):void {
			rects.push(rect);
		}
		
		// Elimina todas las líneas
		public function removeAllLines():void { lines = []; }

		// Elimina todos los rectángulos
		public function removeAllRects():void { rects = []; }
		
		protected function checkLinesCollision(r:Rectangle):Array {
			var clines:Array = [];
			for each (var l:Line in lines) if (Geometry.collisionLineRectangle(l, r)) clines.push(l);
			return clines;
		}
		
		private function getDisplacedRectangle(r:Rectangle, d:Point) {
			var r2:Rectangle = r.clone();
			r2.offsetPoint(d);
			return r2;
		}
		
		// Prueba a mover un rectángulo con un vector director. Devuelve
		// el vector director mas apropiado para la dirección dada.
		public function collision(r:Rectangle, d:Point):Point {
			if (!d.length) return d;
			
			var clinesAfter:Array = checkLinesCollision(getDisplacedRectangle(r, d));
			
			// Si no hay colisión, se devuelve sin problemas
			if (clinesAfter.length == 0) return d.clone();
			
			for each (var line:Line in clinesAfter) {
				var vd:Point = line.getDirector();
				vd.normalize(1);
				vd.normalize(vd.x * d.x + vd.y * d.y);
				if (!checkLinesCollision(getDisplacedRectangle(r, vd)).length) return vd;
			}
			
			if (!checkLinesCollision(getDisplacedRectangle(r, new Point(d.x,   0))).length) return new Point(d.x,   0);
			if (!checkLinesCollision(getDisplacedRectangle(r, new Point(  0, d.y))).length) return new Point(  0, d.y);

			return checkLinesCollision(r).length ? d : new Point(0, 0);
		}		
	}
}