package flash.geom {
	import flash.geom.*;
	
	// Clase que se encarga de almacenar geometrías (líneas y rectángulos)
	// para determinar colisiones con objetos y evitarlas.
	public class Geometry {		
		// NOTA: Ha de hacerse una función a parte ya que el Rectangle.intersect, si hay un
		// rectángulo sin área no lo tiene en cuenta, y por lo tanto al comprobar una línea
		// vertical con un rectángulo falla.
		static public function collisionRectangle2(r1:Rectangle, r2:Rectangle):Boolean {
			return !((r1.left <= r2.right) && (r1.right >= r2.left) && (r1.top <= r2.bottom) && (r1.bottom >= r2.top));
		}
		
		// Realiza la prueba de colisión entre una línea y un rectángulo
		// El rectángulo debe estar normalizado (width, height) >= 0
		static public function collisionLineRectangle(l:Line, r:Rectangle):Boolean {
			// Comprueba que los rectángulos limitantes interseccionen como requisito inicial
			//if (!r.intersects(getLineBoundingBox(l))) return false;
			if (collisionRectangle2(r, getLineBoundingBox(l))) return false;			
			
			var r2 = normalizeRectangle(r);
			
			// Obtiene el vector director de la recta
			var director:Point = l.getDirector();
			
			return !compareSignArray([
				relativePoint(director, (r2.topLeft).subtract(l.p1)),
				relativePoint(director, (r2.bottomRight).subtract(l.p1)),
				relativePoint(director, (new Point(r2.right, r2.top)).subtract(l.p1)),
				relativePoint(director, (new Point(r2.left, r2.bottom)).subtract(l.p1))				
			]);
		}		
		
		// Compara el signo de un array de números, devuelve si el signo es el mismo en todos o no.
		static public function compareSignArray(l:Array):Boolean {
			// Quitamos todos los posibles elementos 0 del principio
			while (l.length && l[0] == 0) l.shift();
			// Comprobamos que haya al menos dos elementos
			// si no hay dos elementos, el signo es el mismo
			if (l.length <= 1) return true;
			// Comprobamos el signo del primer elemento
			var first:Boolean = (l[0] > 0);
			// Nos recorremos toda la lista
			for (var n:uint = 1; n < l.length; n++) {
				// Los elementos 0 no los tenemos en cuenta
				if (l[n] == 0) continue;
				// Si el signo de algún elemento es distinto del primero, el signo es diferente
				if (first != (l[n] > 0)) return false;
			}
			// Si no hemos encontrado ningún signo distinto, todos ellos tienen el mismo signo
			return true;
		}

		// Normaliza un rectángulo de forma que (width, height) >= 0
		static public function normalizeRectangle(r:Rectangle):Rectangle {
			var r2 = r.clone();
			
			if (r2.width  < 0) {
				var cwidth = r2.width;
				r2.left += cwidth;
				r2.width = -cwidth;
			}
			
			if (r2.height < 0) {
				var cheight = r2.height;
				r2.top  += cheight;
				r2.height = -cheight;
			}
			
			return r2;
		}
		
		// Obtenemos el rectángulo que envuelve a una línea
		static public function getLineBoundingBox(l:Line):Rectangle {
			var p1 = new Point(), p2 = new Point();
			
			// Reordena la coordenada x
			if (l.p1.x < l.p2.x) { p1.x = l.p1.x; p2.x = l.p2.x;
			} else { p1.x = l.p2.x; p2.x = l.p1.x; }
			
			// Reordena la coordenada y
			if (l.p1.y < l.p2.y) { p1.y = l.p1.y; p2.y = l.p2.y;
			} else { p1.y = l.p2.y; p2.y = l.p1.y; }
			
			return new Rectangle(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
		};

		// Obtiene la coordenada Z del producto vectorial A(x, y, 0) * B(x, y, 0)
		// que determina la posición relativa de un punto sobre una recta.
		static public function relativePoint(a:Point, b:Point) {
			return (a.x * b.y) - (b.x * a.y);
		}		
	}
}