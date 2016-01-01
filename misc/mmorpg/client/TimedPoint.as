package {
	import flash.geom.Point;
	
	dynamic class TimedPoint extends Point {
		var time:Number;
		
		function TimedPoint(time:Number, point:Point) {
			this.time = time;
			super(point.x, point.y);
		}
	}
}