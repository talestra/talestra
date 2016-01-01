module mmorpg.net.packet;

import imports;

enum GAME_PACKET : ushort {
	LOGIN   = 0x00,
	LOGOUT  = 0x01,
	INFO    = 0x02,

	CREATE  = 0x10,
	REMOVE  = 0x11,

	CHAT    = 0x20,

	MOVING  = 0x30,

	PING    = 0xFF,
}

class Packet : MemoryStream {
	GAME_PACKET id;

	this(GAME_PACKET id, ubyte[] data = []) {
		this.id = id;
		super(data);
	}

	ubyte[] pack() {
		ubyte[2] temp;
		ubyte[] ret;
		ubyte[] data = this.data();
		ushort *shtemp = cast(ushort *)&temp[0];
		*shtemp = data.length + 4;
		ret ~= temp;
		*shtemp = this.id;
		ret ~= temp;
		ret ~= data;
		return ret;
	}

	void readStringLen16(out char[] string) {
		ushort len;
		ubyte[] temp;
		read(len); temp.length = len;
		read(temp);
		string = cast(char[])temp;
	}

	void writeStringLen16(char[] string) {
		write(cast(ushort)string.length);
		writeString(string);
	}
}

// Clase que procesa paquetes enviados a un buffer
class PacketSocket {
	ubyte[] buffer;
	Socket socket;
	bool error;

	// Constructor
	this(Socket socket) {
		this.socket = socket;
		error = false;
	}

	// Destructor
	~this() {
		if (socket) socket.close();
	}

	// Envíamos un paquete
	bool send(Packet p) {
		socket.send(p.pack());
		return true;
	}

	// Recibimos un paquete
	Packet recv() {
		ubyte[] ret;

		// Comprobamos que el paquete está completamente disponible
		if (buffer.length < 2) return null;

		ushort packetLength = *(cast(ushort *)(buffer.ptr));

		if (buffer.length < packetLength) return null;

		GAME_PACKET id = cast(GAME_PACKET)*(cast(ushort *)(buffer.ptr) + 1);

		ret.length = buffer.length - 4;
		ret[0 .. ret.length] = buffer[4 .. buffer.length];
		buffer.length = 0;

		//writefln("RECV(%d, %d)", id, ret.length);

		return new Packet(id, ret);
	}

	// Determinamos si hay algún paquete disponible
	bool packetAvailable() {		
		// Hemos de encontrar la longitud del paquete
		if (buffer.length < 2) {
			ubyte[] temp;
			temp.length = 2 - buffer.length;
			int len = socket.receive(temp);
			if (len == 0) error = true;
			if (len > 0) buffer ~= temp[0 .. len];
		}		

		// Ya tenemos la longitud del paquete, vamos a cargarlo
		if (buffer.length >= 2) {
			writefln("[r: %d] : %s", buffer.length, buffer);
			
			ushort packetLength = *cast(ushort *)buffer.ptr;

			ubyte[] temp; temp.length = packetLength - buffer.length;
			int len = socket.receive(temp);
			if (len == 0) {
				error = true;
				return false;
			}
			//writefln(len);
			buffer ~= temp[0 .. len];
			if (buffer.length >= packetLength) return true;
		}

		return false;
	}

	// Indicamos si el socket sigue activo
	bool isAlive() {
		if (error) return false;
		if (!socket) return false;
		return socket.isAlive;
	}
}
