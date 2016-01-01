package {
	import flash.geom.Point;	
	
	class SplinePoint {
		var x:Spline;
		var y:Spline;
		private var valid:Boolean;
		
		public function SplinePoint() {
			x = new Spline([]);
			y = new Spline([]);
			recalc();
		}
		
		public function clearPoints(autoRecalc:Boolean = true):void {
			x.points = [];
			y.points = [];
			valid = false;
			if (autoRecalc) recalc();
		}
		
		public function addPoint(time:Number, point:Point, autoRecalc:Boolean = true):void {			
			x.points.push(new Point(time, point.x));
			y.points.push(new Point(time, point.y));
			valid = false;
			if (autoRecalc) recalc();
		}
		
		public function recalc():void {
			if (valid) return;
			x.recalc();
			y.recalc();
			valid = true;
		}
		
		public function get maxTime():Number {
			var xpl = x.points.length;
			if (xpl == 0) return 0;
			return x.points[xpl - 1].x;
		}

		public function get maxTime2():Number {
			var xpl = x.points.length;
			if (xpl <= 1) return x.points[0].x;
			return x.points[xpl - 2].x;
		}
		
		public function getPoint(time:Number):Point {
			return new Point(x.Get(time), y.Get(time));
		}
		
		public function clearTo(time:Number):void {
			var i:int = x.LocateIndex(time);
			for (var n = 0; n < i - 1; n++) {
				x.points.shift();
				y.points.shift();
			}
		}
	}
}