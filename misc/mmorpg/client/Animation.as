package {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import flash.net.URLRequest;
	import flash.net.URLLoader;

    public class Animation {
		public static var animations:Array = [];
		public static var loadedCount = 0;
		public static var mainClip;
		
		public static function loadingStart():void {
			if (!mainClip.ploader) return;
			
			clearInterval(mainClip.ploader.timer);
			mainClip.ploader.timer = setInterval(function() {
				mainClip.ploader.alpha += 0.1;
				if (mainClip.ploader.alpha >= 1)  {
					clearInterval(mainClip.ploader.timer);
				}
			}, 40);
			
			mainClip.addChild(mainClip.ploader);
		}

		public static function loadingStop():void {
			if (!mainClip.ploader) return;
			
			clearInterval(mainClip.ploader.timer);
			mainClip.ploader.timer = setInterval(function() {
				mainClip.ploader.alpha -= 0.1;
				if (mainClip.ploader.alpha <= 0)  {
					clearInterval(mainClip.ploader.timer);
					mainClip.removeChild(mainClip.ploader);
				}
			}, 40);
			
			mainClip.addChild(mainClip.ploader);
		}
		
		public static function get(id, url, callback2):void {
			var loader:Loader = new Loader();
			
			if (loadedCount == 0) loadingStart();
			
			loadedCount++;
			
			var callback = function(anim) {
				loadedCount--;
				
				if (loadedCount == 0) loadingStop();
				
				callback2(anim);
			};
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event) {
				var movie:MovieClip = MovieClip(loader.content);
							
				var xml = movie.xml;
				var images = movie.bitmaps;
				var ganimations = {};
				var cuts = {};
				var points = {};
				var lines = [];
	
				for each (var cut:XML in xml.child("cut")) {
					cuts[cut.attribute('id')] = {
						'bitmap' : images[cut.attribute('imageid').toString()],
						'x'      : getValue(cut.attribute('x').toString()),
						'y'      : getValue(cut.attribute('y').toString()),
						'cx'     : getValue(cut.attribute('centerx').toString()),
						'cy'     : getValue(cut.attribute('centery').toString()),
						'width'  : getValue(cut.attribute('width').toString()),
						'height' : getValue(cut.attribute('height').toString())
					};
				}
				
				for each (var point:XML in xml.child("point")) {
					points[point.attribute('id')] = new Point(
						getValue(point.attribute('x').toString()),
						getValue(point.attribute('y').toString())
					);
				}				

				for each (var line:XML in xml.child("line")) {
					lines.push(new Line(
						new Point(getValue(line.attribute('x1').toString()), getValue(line.attribute('y1').toString())),
						new Point(getValue(line.attribute('x2').toString()), getValue(line.attribute('y2').toString()))
					));
				}				
				
				for each (var animation:XML in xml.child("animation")) {
					var canimation = [];
					for each (var frame:XML in animation.child("frame")) {
						var cframe = [];
						cframe.time = parseInt(frame.attribute('time').toString());
						for each (var put:XML in frame.child("put")) {
							cframe.push({
								x     : dvalue(put.attribute('x'    ).toString(), 0),
								y     : dvalue(put.attribute('y'    ).toString(), 0),
								alpha : dvalue(put.attribute('alpha').toString(), 1),
								size  : dvalue(put.attribute('size' ).toString(), 1),
								angle : dvalue(put.attribute('angle').toString(), 0),
								cut   : cuts[put.attribute('cutid').toString()]
							});
						}
						canimation.push(cframe);
					}
					ganimations[animation.attribute('id').toString()] = canimation;
				}

				ganimations.cuts    = cuts;
				ganimations.images  = images;
				ganimations.name    = dvalue(xml.attribute('name').toString(), id);
				ganimations.objects = dvalue(xml.attribute('objects').toString(), 0);
				ganimations.points  = points;
				ganimations.lines   = lines;
				ganimations.height  = dvalue(xml.attribute('height').toString(), undefined);

				animations[ganimations.name] = ganimations;

				if (callback) callback(ganimations);
			});
			
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent) {
				if (callback) callback(null);
			});
			
			loader.load(new URLRequest(url));			
		}
		
		// Función auxiliar para obtener valores con multiplicaciones
		private static function getValue(s:String) {
			var a = 1;
			for each(var ac:Number in s.split('*')) a *= ac;
			return a;
		}

		private static function dvalue(v, d) {
			return (!v && v !== 0) ? d : v;
		}		
	}
}