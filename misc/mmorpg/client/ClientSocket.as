package {
	import flash.utils.Endian;
	import flash.net.Socket;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.system.Security;
	
	dynamic public class ClientSocket extends Socket {
		function onConnect() {
		}
		
		function onError() {
		}
		
		function onClose() {
		}
		
		function onNewPacket() {
			processPackets();
		}
		
		private var packetHandlers:Array = [];
		private var packetLength = 0;
		private var packets:Array = [];
		
		private var host:String = 'localhost';
		private var port:int = 8080;
		
		// Constructor
		public function ClientSocket() {
			this.endian = Endian.LITTLE_ENDIAN;
			addEventListener(Event.CLOSE, processClose);
			addEventListener(Event.CONNECT, processConnect);
			addEventListener(IOErrorEvent.IO_ERROR, processError);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, processSecurityError);
			addEventListener(ProgressEvent.SOCKET_DATA, processData);
		}
		
		// Función que conecta el socket al servidor
		override public function connect(host:String, port:int):void {
			flash.system.Security.allowDomain("*");
			flash.system.Security.loadPolicyFile('http://' + host + '/crossdomain.xml');
			this.host = host;
			this.port = port;
			reconnect();
		}
		
		public function reconnect() {
			super.connect(host, port);
		}
		
		// Procesamos el cierre de la conexión
		private function processClose(event:Event):void {
			onClose();
		}

		// Procesamos el establecimiento de la conexión con el servidor
		private function processConnect(event:Event):void {
			onConnect();
		}
		
		// Procesamos un error de seguridad
		private function processSecurityError(event:SecurityErrorEvent):void {
			onError();
		}
		
		// Procesamos un error en el socket
		private function processError(event:IOErrorEvent):void {
			onError();
			onClose();
		}

		// Envía un paquete al servidor
		public function sendPacket(packet:Packet, autoFlush:Boolean = true) {
			// Escribimos la longitud completa del paquete
			writeShort(packet.length + 4);
			// Escribimos el id del paquete
			writeShort(packet.id);
			// Escribimos los datos del paquete
			writeBytes(packet);
			// Volcamos el contenido del socket al buffer
			if (autoFlush) flush();
		}
		
		// Registra un manejador de paquete
		public function registerPacketHandler(packetId:int, packetHandler:Function) {
			packetHandlers[packetId] = packetHandler;		
		}
		
		// Procesa un paquete recibido
		public function processPackets() {
			if (!packets.length) return;
			
			// Extraemos el primer paquete de la cola
			var packet:Packet = packets.shift();
			
			// Comprobamos si sabemos procesarlo
			if (packetHandlers[packet.id] is Function) {
				// Llamamos al callback encargado de procesar el paquete
				if (!packetHandlers[packet.id](packet)) {
					// Si no se pudo procesar el paquete, por por ejemplo
					// algún problema de concurrencia, se vuelve a introducir el paquete
					packets.unshift(packet);
				}
			}
			// Si no sabemos procesar el paquete, mostramos una alerta
			else {
				trace("Packet " + packet + " unprocessed");
			}
		}
		
		private function processData(event:ProgressEvent):void {
			// Mientras hayan dados para leer
			while (bytesAvailable) {
				// Si no hemos determinado la longitud del paquete todavía
				if (packetLength == 0) {
					if (bytesAvailable < 2) return;		
					packetLength = readUnsignedShort() - 2;
				}
				
				// Comprobamos que tenemos suficientes datos en el socket para completar el paquete
				if (bytesAvailable < packetLength) return;
	
				// Leemos el paquete
				var packet = new Packet(readUnsignedShort());
				readBytes(packet, 0, packetLength - 2); packetLength = 0; packet.position = 0;				
				
				// Enviamos el paquete a la cola para procesarlo
				packets.push(packet);
				
				onNewPacket();
			}
		}
	}
}