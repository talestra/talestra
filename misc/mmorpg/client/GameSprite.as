package {
    import flash.display.*;
    import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.filters.*;
	import fl.controls.List;

    public class GameSprite extends MovieClip {
		// Grupo de animaciones
		private var ganimation;
		// Animación actual
		private var animation;
		// Frame actual
		private var frame = 0;
		// Subsprites
		private var puts = [];
		// Payload de tiempo
		private var time = 0;
		// Multiplicador de tiempo
		public var multiplier = 1;
		
		public var spriteHeight:Number = 56;
				
		// Constructor
        public function GameSprite(ganim, anim = 'default') {
			ganimation = ganim;
			if (ganim.height) spriteHeight = ganim.height;
			setAnimation(anim);
        }
				
		protected function drawPut(id, put) {
			var cut = put.cut;
			var matrix = new Matrix();
			var sprite = new Sprite();			
			matrix.translate(-cut.x, -cut.y);
			//sprite.graphics.beginBitmapFill(cut.bitmap, matrix, false, true);
			sprite.graphics.beginBitmapFill(cut.bitmap, matrix, false, false);
			sprite.graphics.drawRect(0, 0, cut.width, cut.height);
			sprite.graphics.endFill();
			sprite.x = put.x - cut.cx;
			sprite.y = put.y - cut.cy;
			puts[id] = addChild(sprite);
		}
		
		protected function clearPuts() {
			graphics.clear();
			for (var n = 0; n < puts.length; n++) removeChild(puts[n]);			
			puts = [];
		}
		
		protected function getFrame() {
			if (!animation in ganimation) return undefined;
			if (!frame in ganimation[animation]) return undefined;
			return ganimation[animation][frame];
		}
		
		protected function update() {
			var cframe = getFrame();
			if (!cframe) return;
			clearPuts();
			for (var n = 0; n < cframe.length; n++) drawPut(n, cframe[n]);
		}
		
		protected function processNextFrame() {
			frame++;
			if (frame >= ganimation[animation].length) frame = 0;
			update();
		}
		
		public function addTime(time) {
			this.time += time;
			var cframe = getFrame();
			if (!cframe) return;
			while (this.time >= cframe.time * multiplier) {
				this.time -= cframe.time * multiplier;
				processNextFrame();
			}
		}
		
		public function setAnimation(anim) {
			if (anim == animation) return;
			if (!(anim in ganimation)) {
				if (!animation) anim = 'default';
				
				if (!(anim in ganimation)) {
					//trace("La animación '" + anim + "' no existe");
					return;
				}
			}
			
			animation = anim;
			
			//frame = 0;			
			//time = 0;
			
			frame = frame % ganimation[animation].length;
			
			update();
		}
    }
}