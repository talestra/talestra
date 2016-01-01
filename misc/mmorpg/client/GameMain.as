package {
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.geom.Point;
	import flash.display.*;	
	import flash.events.Event;
	import flash.utils.*;
	import fl.events.ComponentEvent;
	import fl.controls.List;
	import flash.geom.*;

	import flash.filters.BlurFilter;
	
	import Packet;
	import ClientSocket;
	import GameSprite;
	import GameCharacter;
	import Animation;	

	// Singletón
	dynamic public class GameMain extends ClientSocket {
		// Tiempo de diferencia con el servidor
		private var diffTime:Number;
		private var screen;
		private var stage:Stage;
		private var sstatusTimer;
		
		private var geometry:GeometryContainer;

		// Camara
		// La cámara contiene capas y está por debajo del Interfaz de Usuario. Se utiliza para
		// mover todos los objetos visibles del escenario a la vez (simulándo una cámara)
		var camera:MovieClip;
		
		// Capas
		// Capa de sprites. Se encarga de almacenar los sprites ordenados por coordenada y.
		var spriteLayer:MovieClipOrdered;
		// Capa de información. Se encarga de almacenar información adicional a los sprites:
		// como nombres de los personajes o texto.
		var infoLayer:MovieClipOrdered;

		// Collision lines
		var collisionLines:Sprite;
		var collisionFirstPoint:Point;
		//var editingCollisionLines:Boolean = true;
		var editingCollisionLines:Boolean = false;
		var preventEditingCollisionLines:Boolean = false;
		
		var characters = {};
		var charaid = -1;		
		var angleTable = {};		
		var sceneanim;		
		var tickInterval;				
		var closed:Boolean = false;		
		var animui;		
		var screenSize:Point = new Point(720, 580);				
		var tickc = 0;
		
		function updateCollisionLines() {
			var g:Graphics = collisionLines.graphics;
			g.clear();
			if (!editingCollisionLines) return;
			g.lineStyle(2, 0xFF0000, 1.0);
			for each (var line:Line in geometry.getLines()) {
				g.moveTo(line.p1.x, line.p1.y);
				g.lineTo(line.p2.x, line.p2.y);
			}
			collisionLines.cacheAsBitmap = true;
		}
		
		// Constructor singletón
		public static var instance:GameMain = null;
		public function GameMain(obj) {
			instance = this; super();
			closed = true;
			screen = obj;
			initializeGame();
			try { screen.removeChild(screen.chat); } catch (e) { }
			stage = Stage(screen.stage);
			
			stage.frameRate = 40;
			stage.scaleMode = StageScaleMode.NO_BORDER;
			stage.quality = StageQuality.HIGH;
			//stage.quality = StageQuality.BEST;			
						
			camera = new MovieClip();
			
			camera.addChild(spriteLayer = new MovieClipOrdered());
			camera.addChild(infoLayer = new MovieClipOrdered());
			camera.addChild(collisionLines = new Sprite());
			
			//screen.addChildAt(camera, 0);
			
			geometry = new GeometryContainerOptimized();
			//geometry = new GeometryContainer();
			
			stage.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
				if (preventEditingCollisionLines) {
					preventEditingCollisionLines = false;
					return;
				}
				if (!editingCollisionLines) return;
																		   
				var m:Point = new Point(e.stageX - camera.x, e.stageY - camera.y);
				if (e.ctrlKey || e.shiftKey || e.altKey) {
					collisionFirstPoint = null;
					updateCollisionLines();
					return;
				}
				
				if (collisionFirstPoint) {
					geometry.addLine(new Line(collisionFirstPoint, m));
					collisionFirstPoint = m.clone();
				}
				collisionFirstPoint = m.clone();
			});

			stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {																				
				if (!editingCollisionLines) return;

				var m:Point = new Point(e.stageX - camera.x, e.stageY - camera.y);
				if (!collisionFirstPoint) return;
				updateCollisionLines();
				var g:Graphics = collisionLines.graphics;
				g.lineStyle(3, 0x0000FF, 1.0);
				g.moveTo(collisionFirstPoint.x, collisionFirstPoint.y);
				g.lineTo(m.x, m.y);
			});
			
			updateCollisionLines();						
			
			//spriteLayer.filters = [new BlurFilter(5, 5)]
						
			var ccontext:List = List(screen.ccontext);			

			ccontext.addEventListener(Event.CHANGE, function(e:Event):void {				
				ccontext.x = -100;
				ccontext.y = 0;
				screen.chat.texti.setFocus();
				switch (ccontext.selectedItem.action) {
					// Hablar
					case 'talk':
						messageAlert("Te dispones a hablar con <b>" + GameCharacter.focused.spriteName + "</b>");
					break;
					// Retar
					case 'challenge':
						if (charaid in characters && characters[charaid] === GameCharacter.focused) {							
							messageAlert("No te puedes retar a ti mismo");
						} else {
							messageAlert("Acabas de retar a <b>" + GameCharacter.focused.spriteName + "</b>");
						}
					break;
					// Susurrar
					case 'whisper':
						if (charaid in characters && characters[charaid] === GameCharacter.focused) {							
							messageAlert("No te puedes susurrar a ti mismo");
						} else {
						}
					break;
					// Cancelar
					default: case 'cancel':
						trace("Cancelar");
					break;
				}
				GameCharacter.globalFocus(null);
			});
			
			var ccontext_exittimeout;

			ccontext.addEventListener(MouseEvent.MOUSE_OVER, function(e:Event):void {
				try { clearTimeout(ccontext_exittimeout); } catch (e) { }
			});			
			
			ccontext.addEventListener(MouseEvent.MOUSE_OUT, function(e:Event):void {
				try { clearTimeout(ccontext_exittimeout); } catch (e) { }
				if (ccontext.x < 0) return;
				ccontext_exittimeout = setTimeout(function() {
					ccontext.x = -100;
					ccontext.y = 0;
					screen.chat.texti.setFocus();
					GameCharacter.globalFocus(null);
				}, 200);
			});
			
			Animation.get('ui', 'ui.swf', function(anim) {
				animui = anim;
			});		
		}
				
		static public function sign(v:Number):int {
			return (v > 0) ? 1 : ((v < 0) ? -1 : 0);
		}
		
		function getTime():Number {
			return (new Date()).time;
		}
		
		private function messageAlert(text:String) {
			screen.chat.datai.htmlText = screen.chat.datai.htmlText + '<font color="#AF3030">' + text + "</font>\n";
			screen.chat.datai.verticalScrollPosition = screen.chat.datai.maxVerticalScrollPosition;						
		}

		private function messagePlayer(id:Number, name:String, text:String) {
			screen.chat.datai.htmlText = screen.chat.datai.htmlText + '<b>' + name + '</b>: ' + text + "\n";
			screen.chat.datai.verticalScrollPosition = screen.chat.datai.maxVerticalScrollPosition;						
			function attachText() {
				if (!(id in characters)) {
					setTimeout(attachText, 200);
					return false;
				}
				var character = characters[id];
				character.setText(text);
			}			
			attachText();
		}
		
		// Evento generado al conectar con el servidor
		override function onConnect() {
			closed = false;
			//if (closed) return;
			
			//screen.addChildAt(camera, 0);
			
			spriteLayer.removeAll();
			infoLayer.removeAll();
			charaid = -1;
			characters = {};
			
			geometry.removeAllLines();
			
			//trace('onConnect');
			
			screen.sstatus.alpha = 1;
			if (!screen.contains(screen.sstatus)) screen.addChild(screen.sstatus);
			
			try { clearInterval(sstatusTimer); } catch (e) { }
			
			sstatusTimer = setInterval(function() {
				screen.sstatus.alpha -= 0.05;
				if (screen.sstatus.alpha <= 0) {
					screen.removeChild(screen.sstatus);
					clearInterval(sstatusTimer);
				}
			}, 20);			
		}
		
		// Evento generado al producirse un error
		override function onError() {
			if (closed) return;
			//trace('onError');
		}
		
		// Evento generado al cerrarse la conexión con el servidor
		override function onClose() {
			if (closed) return;
			
			closed = true;
			//trace('onClose');
			
			if (!screen.contains(screen.sstatus)) screen.addChild(screen.sstatus);
			
			try { clearInterval(sstatusTimer); } catch (e) { }
			
			sstatusTimer = setInterval(function() {
				screen.sstatus.alpha += 0.05;
				if (screen.sstatus.alpha >= 1) clearInterval(sstatusTimer);
			}, 20);			

			setTimeout(function() { reconnect(); }, 3000)
		}		
		
		// Evento generador cuando llega un nuevo paquete
		override function onNewPacket() {
			//processPackets();
		}
		
		function onPacketLogin(packet:Packet):Boolean {
			var seed:uint = packet.readUnsignedInt();
			
			var spacket:Packet = new Packet(Packet.LOGIN);
			spacket.writeUTF('user');
			spacket.writeUTF(flash.utils.md5.hash(flash.utils.md5.hash('password') + seed.toString()));
			sendPacket(spacket);
			
			return true;
		}

		function onPacketPing(packet:Packet):Boolean {
			var pingTime:Number = getTime();
			var serverTime:Number = packet.readLong();
			diffTime = pingTime - serverTime;
			var packet:Packet = new Packet(Packet.PING);
			packet.writeLong(pingTime);
			sendPacket(packet);
			return true;
		}
		
		private var animStatus = [
			'none',
			'card',
			'chat'
		];
		
		function onPacketCreate(packet:Packet):Boolean {
			var id     = packet.readLong();
			var zcname = packet.readUTF();
			var sprite = packet.readUTF();
			var p      = packet.readDoublePoint();   // Posición
			var s      = packet.readFloatPoint(); // Tamaño
			var d      = packet.readBytePoint();  // Dirección
			var v      = packet.readBytePoint();  // Velocidad
			var busy   = packet.readByte();  // Ocupado
			var type   = packet.readUnsignedByte();  // Tipo de personaje
			
			//trace('onPacketCreate', id, zcname, sprite, "P", p, "S", s, "D", d, "V", v);
			if (id in characters) RemoveCharacter(id);
						
			CreateCharacter(zcname, sprite, p, id, function(character) {
				character.p = p;
				character.d = d;
				character.objectSize = s;
				character.v = v;
				character.time = getTime();
				character.setStatus(animui, animStatus[busy]);
				character.type = type;
				if (id === charaid) character.current = true;
				trace(character.objectSize);
				character.updateObject();
			});
					
			return true;
		}
		
		function onPacketChat(packet:Packet):Boolean {
			var id:Number = packet.readLong();
			var name:String = packet.readUTF();
			var text:String = packet.readUTF();			
			if (name.length) {
				messagePlayer(id, name, text);
			} else {
				messageAlert(text);
			}
			return true;
		}
		
		function onPacketLogout(packet:Packet):Boolean {
			//trace("onPacketLogout");
			return true;
		}

		function onPacketRemove(packet:Packet):Boolean {
			var id:Number = packet.readLong();
			//trace('onPacketRemove', id);
			RemoveCharacter(id);
			return true;
		}

		function onPacketMoving(packet:Packet):Boolean {
			//trace("onPacketMoving");
			var id = packet.readLong();
			
			if (!(id in characters)) return true;			
			var character = characters[id];
			
			var time = packet.readLong() + diffTime;
			var p    = packet.readDoublePoint();
			var d    = packet.readBytePoint();
			var v    = packet.readBytePoint();
			var busy = packet.readByte();
			
			character.motion.push(new Waypoint(time + 100, p, d, v));
			character.setStatus(animui, animStatus[busy]);
					
			return true;
		}

		function onPacketInfo(packet:Packet):Boolean {
			var id:Number = packet.readLong();
			var scene:String = packet.readUTF();
			
			if (charaid in characters) characters[charaid].current = false;
			charaid = id;
			if (charaid in characters) {
				characters[charaid].current = true;
			}
			
			Animation.get(scene, 'scenes/' + scene + '.swf', function(anim) {					
				var bgsprite:GameSprite = new GameSprite(anim, 'background');				
				spriteLayer.addChild(bgsprite);
				
				sceneanim = anim;

				for (var pointid in anim.points) {
					var point = anim.points[pointid];
					var sprite:GameSprite = new GameSprite(anim, 'object' + pointid);
					sprite.x = point.x;
					sprite.y = point.y;
					spriteLayer.addChild(sprite);
				}
				
				geometry.removeAllLines();
				geometry.removeAllRects();
				for each (var line:Line in anim.lines) geometry.addLine(line);
				
				screen.addChildAt(camera, 0);
			});	
			
			return true;
		}
		
		private function registerPacketHandlers() {
			registerPacketHandler(Packet.LOGIN , onPacketLogin);
			registerPacketHandler(Packet.LOGOUT, onPacketLogout);
			registerPacketHandler(Packet.INFO  , onPacketInfo);
			
			registerPacketHandler(Packet.CREATE, onPacketCreate);
			registerPacketHandler(Packet.REMOVE, onPacketRemove);
			registerPacketHandler(Packet.MOVING, onPacketMoving);
			
			registerPacketHandler(Packet.CHAT  , onPacketChat);
			registerPacketHandler(Packet.PING  , onPacketPing);
		}
		
		function sendButton(event:ComponentEvent):void {
			if (closed) return;
			var packet = new Packet(Packet.CHAT);
			packet.writeUTF(screen.chat.texti.text.substr(0, 512));
			sendPacket(packet);
			screen.chat.texti.text = '';
		}
		
		function blogoutClick(event:ComponentEvent):void {
			if (closed) return;
			stop();
			//screen.gotoAndStop('login');
			screen.addChild(screen.loader);
			screen.loader.alpha = 1;
			screen.loader.content.onEnter();
		}
		
		function blinesClick(event:ComponentEvent):void {
			preventEditingCollisionLines = true;
			event.stopPropagation();
			if (closed) return;
			editingCollisionLines = !editingCollisionLines;
			updateCollisionLines();
		}		
		
		private function registerUIHandlers() {			
			screen.chat.sendi.addEventListener(ComponentEvent.BUTTON_DOWN, sendButton, false, 0, true);
			screen.chat.texti.addEventListener(ComponentEvent.ENTER, sendButton, false, 0, true);
			screen.chat.blogout.addEventListener(ComponentEvent.BUTTON_DOWN, blogoutClick);			
			screen.chat.blines.addEventListener(ComponentEvent.BUTTON_DOWN, blinesClick);
			screen.chat.texti.setFocus();			
		}
				
		function tick() { try {
			if (closed) return;
			processPackets();			
			
			spriteLayer.resort();
			infoLayer.resort();
			
			for (var key in characters) {
				var character = characters[key];
				if (!character) continue;
				
				if (character.motion.length) {					
					if (getTime() >= character.motion[0].time) {
						var wp:Waypoint = character.motion[0];
						var r = character.p.subtract(wp.p);
						if (r.length <= 6) {
							character.time = getTime();
							character.move(wp.p);
							character.d = wp.d;
							character.v = wp.v;
							character.motion.shift();
						} else {
							character.v = wp.p.subtract(character.p);
							character.v.normalize(Math.min(4, r.length));
						}
					}					
				}
				
				var charv = character.v;
				var speed = 5;
				
				if (charv.length) {
					var c = (getTime() - character.time) / 400;
					switch (character.motion.length) {
						case 0:  speed *= Math.min(c * 0.99 + 0.15, 1.0); break;
						case 1:  speed *= Math.min(c * 2.00 + 0.30, 1.0); break;
						case 2:  speed *= Math.min(c * 3.00 + 0.35, 1.1); break;
						default: speed *= Math.min(c * 4.00 + 0.45, 1.2); break;
					}
				}
				
				var angle = (getAngle(charv) * Math.PI * 2) / 360;
				var d = new Point(0, 0), d2;
				
				if (charv.length) {
					d = new Point(
						+Math.cos(angle) * speed,
						-Math.sin(angle) * speed
					);
				}
				
				d2 = d.clone();
				
				// Corrector de dirección con geometrías (solo si hay movimiento)
				// Solo debe usarse en el caso de que sea un peronaje local o
				// no queden puntos de control a seguir
				if (d.length > 0 && (characters[charaid] === character || character.motion.length < 2)) {
					if (character.motion.length <= 0 || character.motion[character.motion.length - 1].v.length != 0) {
						d2 = geometry.collision(character.bbox, d);
					}
				}
				
				character.displace(d2);				
				
				if (d.x != 0 || d.y != 0)  {
					character.addTime(d.length);
					character.setAnimation('walk' + pad03(getAngle(character.d)));
				} else {
					character.addTime(10);
					character.setAnimation('stop' + pad03(getAngle(character.d)));
				}
			}
			
			//if (tickc++ % 5) return;
			
			if (charaid in characters) {
				var chara:GameCharacter = characters[charaid];
				var screenSize:Point = new Point(stage.stageWidth, stage.stageHeight);
				var sceneSize:Point = screenSize.clone();
				var requestedPoint:Point = new Point(
					Math.round(-chara.p.x + screenSize.x / 2),
					Math.round(-chara.p.y + screenSize.y / 2)
				);
				
				if (sceneanim) {
					sceneSize = new Point(
						sceneanim.images['background'].width,
						sceneanim.images['background'].height + 100
					);
				}
				
				if (requestedPoint.x > 0) requestedPoint.x = 0;
				if (requestedPoint.y > 0) requestedPoint.y = 0;
				if (requestedPoint.x < -(sceneSize.x - screenSize.x)) requestedPoint.x = -(sceneSize.x - screenSize.x);
				if (requestedPoint.y < -(sceneSize.y - screenSize.y)) requestedPoint.y = -(sceneSize.y - screenSize.y);
				
				camera.x = requestedPoint.x;
				camera.y = requestedPoint.y;
				//trace(screen.width);
				//trace(spriteLayer.localToGlobal(chara.p));
			}
		} catch (e) { trace('Error in tick(): ' + e); }}		

		// Eliminamos un personaje progresivamente del escenario
		function RemoveCharacter(id:Number, progress:Boolean = true):void {			
			if (!progress) {
				spriteLayer.removeChild(character);				
				infoLayer.removeChild(character.infoLayer);
				characters[id] = null;
				return;
			}
			
			if (!(id in characters)) return;
			var character:GameCharacter = characters[id];
			var characterInfo:Sprite = character.infoLayer;
					
			var rcinterval = setInterval(function() {
				character.alpha -= 0.1;
				characterInfo.alpha -= 0.1;
				if (character.alpha <= 0) {
					spriteLayer.removeChild(character);
					infoLayer.removeChild(characterInfo);
					character.alpha = 1;
					characterInfo.alpha = 1;
					characters[id] = null;
					clearInterval(rcinterval);
				}
			}, 40);
		}
				
		function CreateCharacter(cname, anim, p:Point, id = 0, callback = undefined) {
			if (closed) return;
			if (id in characters) {
				RemoveCharacter(id);
			}
			
			function create(ganim) {
				var sprite = new GameCharacter(cname, ganim, 'stop270');
				sprite.alpha = 0;
				sprite.multiplier = 8;
				sprite.move(p);
				characters[id] = sprite;

				var interval = setInterval(function() {
					sprite.alpha += 0.1;
					if (sprite.alpha >= 1) clearInterval(interval);
				}, 20);
				
				spriteLayer.addChild(sprite);
				infoLayer.addChild(sprite.infoLayer);

				if (callback) callback(sprite);				
			}
			
			Animation.get(anim, 'charas/' + anim + '.swf', create);
		}
		
		function getAngle(p:Point) {
			return angleTable[[sign(p.x), sign(p.y)]];
		}
		
		function pad03(n) {
			try {
				n = n.toString();
				while (n.length < 3) n = '0' + n;
				return n;
			} catch (e) {
				return '000';
			}
		}
		
		function movingWaypoint() {
			if (closed) return;
			if (!charaid in characters) return;
			var character:GameCharacter = characters[charaid];
			var packet:Packet = new Packet(Packet.MOVING);
			packet.writeLong(getTime());
			packet.writeDoublePoint(character.p);
			packet.writeBytePoint(character.d);
			packet.writeBytePoint(character.v);
			sendPacket(packet);
		}

		function movingStart() {
			if (closed) return;
			//trace('movingStart');
			movingWaypoint();
		}

		function movingChangeDirection() {
			if (closed) return;
			//trace('movingChangeDirection');
			movingWaypoint();
		}

		function movingStop() {
			if (closed) return;
			//trace('movingStop');
			movingWaypoint();
		}

		function EventKeyDown(event:KeyboardEvent) {
			if (closed) return;
			if (!(charaid in characters)) return;
			var character = characters[charaid];			

			switch (event.keyCode) {
				case Keyboard.ENTER    : screen.chat.texti.setFocus(); return;
				//case Keyboard.HOME     : screen.chat.datai.verticalScrollPosition = 0; return;
				//case Keyboard.END      : screen.chat.datai.verticalScrollPosition = screen.chat.datai.maxVerticalScrollPosition; return; 
				case Keyboard.PAGE_UP  : screen.chat.datai.verticalScrollPosition -= 5; return; 
				case Keyboard.PAGE_DOWN: screen.chat.datai.verticalScrollPosition += 5; return; 
			}
			
			var bv:Point = character.v.clone();
			
			switch (event.keyCode) {
				case Keyboard.LEFT:  character.v.x = character.d.x = -1; break;
				case Keyboard.RIGHT: character.v.x = character.d.x =  1; break;
				case Keyboard.UP:    character.v.y = character.d.y = -1; break;
				case Keyboard.DOWN:  character.v.y = character.d.y =  1; break;
				default: return;
			}
			
			screen.chat.texti.setFocus();
			
			if (character.v.length) character.d = character.v.clone();
			
			// Empezamos a movernos
			if (!bv.length) {
				movingStart();
			}
			// Cambiamos de dirección
			else if (!bv.equals(character.v)) {
				movingChangeDirection();
			}
		}
		
		function EventKeyUp(event:KeyboardEvent) {
			if (closed) return;
			if (!(charaid in characters)) return;	
			var character = characters[charaid];
			
			var bv:Point = character.v.clone();			

			switch (event.keyCode) {
				case Keyboard.RIGHT: case Keyboard.LEFT:
					if (character.v.y) character.d.x = 0;
					character.v.x = 0;
				break;
				case Keyboard.UP: case Keyboard.DOWN:
					if (character.v.x) character.d.y = 0;
					character.v.y = 0;
				break;
				default: return;
			}
			
			screen.chat.texti.setFocus();
			
			// Dejamos de movernos
			if (!character.v.length) {
				movingStop();	
			}
			// Cambiamos de dirección
			else if (!bv.equals(character.v)) {
				movingChangeDirection();
			}
		}

		private function registerKeyHandlers() {
			screen.addEventListener(KeyboardEvent.KEY_DOWN, EventKeyDown, false, 0, true);
			screen.addEventListener(KeyboardEvent.KEY_UP  , EventKeyUp, false, 0, true);
		}

		private function initializeGame() {
			registerPacketHandlers();
			registerKeyHandlers();

			angleTable[[ 0,  0]] = 270;

			angleTable[[ 1,  0]] =   0;
			angleTable[[ 1, -1]] =  45;
			angleTable[[ 0, -1]] =  90;
			angleTable[[-1, -1]] = 135;
			angleTable[[-1,  0]] = 180;
			angleTable[[-1,  1]] = 225;
			angleTable[[ 0,  1]] = 270;
			angleTable[[ 1,  1]] = 315;
		}

		// Función principal
		public function start(server, port) {
			closed = false;
			connect(server, port);
			tickInterval = setInterval(tick, (1000 / 40));
			
			screen.addChildAt(screen.chat, 1);
			registerUIHandlers();
		}
				
		public function stop() {
			closed = true;
			clearInterval(tickInterval);
			close();
			charaid = -1;
			spriteLayer.removeAll();
			infoLayer.removeAll();
			screen.removeChild(screen.chat);
		}
	}
}