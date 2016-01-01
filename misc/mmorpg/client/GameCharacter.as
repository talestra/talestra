package {
    import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.display.Graphics;
    import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.filters.*;
	import flash.utils.*;
	import fl.controls.List;	

    dynamic public class GameCharacter extends GameSprite {
		public var p:Point; // Posición
		public var d:Point; // Dirección
		public var v:Point; // Velocidad		
		public var blocking;
		public var motion:Array;
		public var time:Number;

		public var infoLayer:Sprite;
		
		private var textObjectTimer;
		private var textObjectTimer2;
		private var textObject:Sprite;
		private var infoText:Sprite;
		private var infoObject:Sprite;
		public var spriteName:String;
		public var displayName:Boolean;
				
		public var bbox:Rectangle;
		
		public var type:uint = 0;		

		public var current:Boolean = false;	
		
		static var focused:GameCharacter;
		
		public var objectSize = 1.0;
		
		public function GameCharacter(cname, ganim, anim = 'default') {
			infoLayer = new Sprite();
			var gsprite:MovieClip = MovieClip(this);

			v = new Point();
			d = new Point();
			p = new Point();
			objectSize = new Point(1, 1);
			motion = [];
			displayName = true;
					
			bbox = new Rectangle(0, 0, 22, 18);			
		
			addEventListener(flash.events.MouseEvent.MOUSE_OVER, function() {				
				gsprite.focus = true;
			});
			
			addEventListener(flash.events.MouseEvent.MOUSE_OUT, function() {
				gsprite.focus = false;				
			});
		
			addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function() {			
				var screen:MovieClip = MovieClip(gsprite.parent.parent.parent);
				GameCharacter.globalFocus(gsprite);
				var ccontext:List = List(screen.ccontext);
				
				ccontext.removeAll();
				switch (type) {
					case 0:
						if (current) {
							ccontext.addItem({ 'label' : 'Cancelar', 'action' : 'cancel' });
						} else {
							ccontext.addItem({ 'label' : 'Retar', 'action' : 'challenge' });
							ccontext.addItem({ 'label' : 'Susurrar', 'action' : 'whisper' });
							ccontext.addItem({ 'label' : 'Cancelar', 'action' : 'cancel' });
						}
					break;
					case 1:
						ccontext.addItem({ 'label' : 'Hablar', 'action' : 'talk' });
						ccontext.addItem({ 'label' : 'Cancelar', 'action' : 'cancel' });
					break;
				}
				ccontext.height = 20 * ccontext.length + 1;
																		   
				ccontext.selectedIndex = -1;
				var np:Point = parent.localToGlobal(new Point(x, y));
				ccontext.x = np.x - 5;
				ccontext.y = np.y - 5;
				screen.chat.texti.setFocus();
			});
			
			updateInfoText(cname);			
			
			updateObject();
			
			//trace(this.transform.matrix);
			//this.transform.matrix = this.transform.matrix.scale(0.5, 0.5);
			
			super(ganim, anim);
		}
		
		public function updateObject() {
			var matrix = new Matrix();
			matrix.scale(objectSize.x, objectSize.y);
			this.transform.matrix = matrix;
		}

		/// Función encargada de colocar un texto a un personaje
		public function setText(text:String):void {
			try { clearTimeout(textObjectTimer); } catch (e) { }
			try { clearTimeout(textObjectTimer2); } catch (e) { }
			
			clearPuts();
			
			//for each (var font:Font in Font.enumerateFonts()) trace(font.fontName);
			textObject = new Sprite();
			var effectedBubble:MovieClip = new MovieClip();
			var textf:TextField = new TextField();			
			//var textFormat:TextFormat = new TextFormat('Hobo Std', 11, 0x563D29, true, false, false);
			var textFormat:TextFormat = new TextFormat('Hobo Std', 11 * objectSize.y, 0x563D29, true, false, false);
			textf.embedFonts = true;
			textf.antiAliasType = flash.text.AntiAliasType.NORMAL;
			textf.width = 180 * objectSize.x;
			textf.wordWrap = true;
			textf.multiline = true;
			textf.autoSize = TextFieldAutoSize.LEFT;
			//textf.setTextFormat(textFormat);
			//style.setStyle("body", body);
			textf.defaultTextFormat = textFormat;
			textf.selectable = false;
			textf.condenseWhite = true;
			
			textf.htmlText = text;
			
			var size:Point = new Point(textf.textWidth + 6, textf.height); 
			var size2:Point = new Point(size.x * 0.55, size.y + 15); 
			
			textf.x = -size.x / 2;
			textf.y = -size.y - 15;
			
			var newpointsy = (size2.y >= 40);
			var newpointsx = (size2.x >= 30);
			
			var graphics:Graphics = effectedBubble.graphics;
			graphics.beginFill(0xE0DFC3);
			graphics.moveTo(0, 0);
			graphics.lineTo(-4, -10);
			
			if (newpointsx) {
				graphics.lineTo(-size2.x * 0.50 - 5, -15);
			}
			graphics.lineTo(-size2.x * 0.95, -10);			
			graphics.lineTo(-size2.x * 1.00, -18);
			
			if (newpointsy) {
				graphics.lineTo(-size2.x * 1.00 - 3, -size2.y * 0.33);
				graphics.lineTo(-size2.x * 1.00 + 3, -size2.y * 0.66);
			}

			graphics.lineTo(-size2.x * 1.00, -size2.y);
			graphics.lineTo(-size2.x * 0.95, -size2.y - 4);
			if (newpointsx) {		
				graphics.lineTo(-size2.x * 0.50 - 5, -size2.y - 1);
			}
		
			if (newpointsx) {	
				graphics.lineTo(size2.x * 0.50 - 5, -size2.y - 3);
			}
			graphics.lineTo(size2.x * 0.95, -size2.y - 4);
			graphics.lineTo(size2.x * 1.00, -size2.y);

			if (newpointsy) {
				graphics.lineTo(size2.x * 1.00 + 3, -size2.y * 0.66);
				graphics.lineTo(size2.x * 1.00 - 3, -size2.y * 0.33);
			}
			
			graphics.lineTo(size2.x * 1.00 - 3, -18);
			graphics.lineTo(size2.x * 0.95 - 3, -15);
			if (newpointsx) {	
				graphics.lineTo(size2.x * 0.50 - 8, -10);
			}
			
			graphics.lineTo(5, -12);
			graphics.lineTo(0, 0);
			graphics.endFill();
			
			effectedBubble.filters = [
				new DropShadowFilter(0, 45, 0xD2A86F, 1, 8, 12, 0.8, 1, true, false, false),
				new DropShadowFilter(4, 45, 0x665433, 1, 8, 8, 0.75, 1, false, false, false)
			];
			
			textObject.addChild(effectedBubble);
			var text2 = new Sprite(); text2.addChild(textf);
			textObject.addChild(text2);	

			//textObject.y = -64;			
			textObject.y = -spriteHeight * objectSize.y;
			
			textObject.cacheAsBitmap = true;			
			
			update();
			
			textObjectTimer = setTimeout(function() {
				textObjectTimer2 = setInterval(function() {
					textObject.alpha -= 0.05;
					if (textObject.alpha <= 0) {
						clearInterval(textObjectTimer2);
						infoLayer.removeChild(textObject);
						textObject = null;
					}
				}, 40);
			}, 30 * text.length + 4444);
		}
		
		public function setStatus(ui, anim) {
			clearPuts();
			infoObject = ui ? new GameSprite(ui, anim) : null;
			update();
		}
		
		public function set focus(has:Boolean):void {
			if (focused === this) has = true;
			
			transform.colorTransform = has ? 
				new ColorTransform(1, 1, 1, 1, 30, 30, 30, 0) :
				new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0)
			;
		}
		
		static public function globalFocus(object) {
			if (focused === object) return;
			var backfocused = focused;
			focused = object;
			if (focused == backfocused) return;
			if (backfocused) backfocused.focus = false;			
			if (focused) focused.focus = true;
		}		
		
		public function updateInfoText(spriteName) {
			infoText = new Sprite();
            var label:TextField = new TextField();
            label.autoSize = TextFieldAutoSize.CENTER;
			label.selectable = false;
            var format:TextFormat = new TextFormat();
            format.font = "Tahoma";
            format.color = 0xFFFFFF;
            format.size = 12 * objectSize.y;
            format.underline = false;
			
			//label.embedFonts = true;
			//label.antiAliasType = flash.text.AntiAliasType.NORMAL;
			
            label.defaultTextFormat = format;
			label.text = (this.spriteName = spriteName);
			label.x = -label.width / 2;
			var rbox = { 'width' : label.width + 4, 'height' : label.height - 1 };
			var box = new Sprite();
			box.graphics.beginFill(0x000000, 0.5);
			box.graphics.drawRect(0, 0, rbox.width, rbox.height);
			box.graphics.endFill();
			box.x = -rbox.width / 2; box.y = 2;
			infoText.addChild(box);			
            infoText.addChild(label);
		}		
		
		override protected function clearPuts() {
			super.clearPuts();
			if (infoText) try { infoLayer.removeChild(infoText); } catch(e) { }
			if (infoObject) try { infoLayer.removeChild(infoObject); } catch(e) { }
			if (textObject) try { infoLayer.removeChild(textObject); } catch(e) { }
		}

		override protected function update() {
			super.update();
			if (displayName && infoText) {
				infoLayer.addChild(infoText);
				infoText.x = 0;
				infoText.y = 6 * objectSize.y;
			}
			if (infoObject) infoLayer.addChild(infoObject);
			if (textObject) infoLayer.addChild(textObject);
		}		
		
		public function move(p:Point) {
			this.p = p.clone();
			updatePosition();
		}

		public function displace(p:Point) {			
			this.p = this.p.add(p);
			updatePosition();
		}

		private function updatePosition() {
			this.x = Math.round(this.p.x);
			this.y = Math.round(this.p.y);
			infoLayer.x = this.x;
			infoLayer.y = this.y;
			//bbox.offset(infoLayer.x - 18, infoLayer.y - 12);
			bbox = new Rectangle(this.p.x - bbox.width / 2, this.p.y - bbox.height / 2, bbox.width, bbox.height);
		}
	}
}