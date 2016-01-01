package {
	import flash.display.MovieClip;
	import flash.display.DisplayObject;

	dynamic class MovieClipOrdered extends MovieClip {		
		private var list:Array = [];
	
		public function MovieClipOrdered() {			
		}
		
		override public function addChild(child:DisplayObject):DisplayObject {
			list.push(child);
			return super.addChild(child);
		}

		override public function removeChild(child:DisplayObject):DisplayObject {
			var index:int = list.indexOf(child); if (index < 0) return child;
			list.splice(index, 1);
			return super.removeChild(child);
		}
		
		public function removeAll() {
			for each (var child in list) super.removeChild(child);
			list = [];
		}
		
		//override public function contains(child:DisplayObject):Boolean { }
		
		public function resort() {
			list.sortOn('y', Array.NUMERIC);
			//for (var n = list.length - 1; n >= 0; n--) this.setChildIndex(list[n], n);
			for (var n:uint = 0; n < list.length; n++) this.setChildIndex(list[n], n);
		}
	}
}