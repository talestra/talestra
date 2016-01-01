package {
	import flash.geom.Point;
	
	dynamic class Waypoint {
		var time:Number;
		var p:Point;
		var d:Point;
		var v:Point;
		
		public function Waypoint(time:Number, p:Point, d:Point, v:Point) {
			this.time = time;
			this.p = p.clone();
			this.d = d.clone();
			this.v = v.clone();
		}
	}
}