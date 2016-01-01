import imports;

//import sqlite3;

import mmorpg.cards;
import mmorpg.util;
import mmorpg.net.packet;

version (Windows) {
	pragma(lib, "wsock32.lib");
	pragma(lib, "kernel32.lib");

	extern(Windows) {
		void Sleep(u32);
		u32 GetTickCount();
		u32 QueryPerformanceCounter(u64 *lpPerformanceCount);
		u32 QueryPerformanceFrequency(u64 *lpFrequency);
	}

	void Rest () { Sleep(0); }
	void Rest1() { Sleep(1); }

	double freq;

	static this() {
		u64 ifreq;
		QueryPerformanceFrequency(&ifreq);
		freq = ifreq;
		freq /= 1000000;
	}

	u64 GetMicro() {
		u64 pcount;
		QueryPerformanceCounter(&pcount);
		return cast(u64)((cast(double)pcount) / freq);
	}

	u64 GetMili() {
		return GetMicro() / 1000;
	}
} else {
	void Rest() { }
	void Rest1() { }
	u64 GetMili() {
		return clock();
	}
}

s64 globalMili;

class Entity {
	static long next_id = 0;
	double x, y;
	int xbox, ybox;
	Server server;
	EntityList elistbox;
	ubyte type;

	void move(double x, double y) {
		int xbox = cast(int)(x / Server.gclistboxsize);
		int ybox = cast(int)(y / Server.gclistboxsize);

		this.x = x;
		this.y = y;

		if (xbox != this.xbox || ybox != this.ybox) {
			this.xbox = xbox;
			this.ybox = ybox;
		}
	}
}

class Character : Entity {
	static ulong next_id = 0;
	ulong id;
	float sizex, sizey;
	byte dx, dy;
	byte vx, vy;
	byte busy;
	char[] name;
	char[] sprite;

	static char[][] sprites = [
		//"spirit",
		"reid",
		"farah",
		"meredy",
		"keele",
		"ras",
		"chat",
		"max",
	];

	static char[][] names = [
		//"Espíritu de Luz",
		"Reid",
		"Farah",
		"Meredy",
		"Keele",
		"Ras",
		"Chat",
		"Max",
	];

	this() {
		name = names[next_id % names.length];
		sprite = sprites[next_id % names.length];
		id = ++next_id;
		sizex = 1;
		sizey = 1;
	}

	this(char[] name, char[] sprite) {
		this.name = name;
		this.sprite = sprite;
		//name = names[next_id % names.length];
		//sprite = sprites[next_id % names.length];
		id = ++next_id;
		sizex = 1;
		sizey = 1;
		type = 0;
	}

	Packet genPacketCreateCharacter() {
		Packet p = new Packet(GAME_PACKET.CREATE);

		p.write(cast(ulong) id);
		p.writeStringLen16(name);
		p.writeStringLen16(sprite);
		p.write(x);
		p.write(y);
		p.write(sizex);
		p.write(sizey);
		p.write(dx);
		p.write(dy);
		p.write(vx);
		p.write(cast(byte)  vy);
		p.write(cast(byte)  busy);
		p.write(cast(ubyte)  type);

		return p;
	}

	Packet genPacketRemoveCharacter() {
		Packet p = new Packet(GAME_PACKET.REMOVE);

		p.write(cast(ulong) id);

		return p;
	}

	void say(char[] text) {
		Packet sp = new Packet(GAME_PACKET.CHAT);
		sp.write(id);
		sp.writeStringLen16(name);
		sp.writeStringLen16(text);
		server.sendAll(sp);
	}
}

class Client : PacketSocket {
	// Estado de la conexión
	enum Status {
		disconnected, // Desconectado
		connected,    // Conectado
		loged,        // Logueado
		cards,        // Jugando a las cartas
		battle,       // En una batalla
		npc           // Hablando con un npc
	} Status status;

	int bufferpos = 0;
	Character character;
	ulong tick = 0;
	Server server;
	Room room;
	bool ping = false;
	bool remove = false;

	// Diferencia ente el tiempo local y el tiempo remoto en milisegundos
	s64 diffTime, pingTime;

	// Semilla utilizada para el login
	u32 loginSeed;

	this(Socket socket, Server server = null) {
		super(socket);
		status = Status.connected;

		//if (rem) {
		if (false) {
			character = new Character("Espíritu de Luz", "spirit");
		} else {
			character = new Character();
		}

		character.server = server;
		character.move(520, 430);
		character.dx = 0;
		character.dy = -1;
		this.server = server;
		onConnect();
		character.busy = 0;
	}

	void move(double x, double y) {
		character.move(x, y);
	}

	// Actualizamos la información en la base de datos
	void store() {
		/*
		Sqlite3 db = server.gamedb;
		try {
			db.performQuery(std.string.format(
				"UPDATE [characters] SET "
					"x=%d,"
					"y=%d,"
				"WHERE gameid=%d"
			, character.x, character.y, 0));
		} catch (Exception e) {
		}
		*/
	}

	// Al cerrar la conexión
	void onClose() {
		// Guardamos el estado actual del cliente en la base de datos
		//store();

		// Informamos al resto de clientes
		server.sendAll(character.genPacketRemoveCharacter());
		character.server.sendStatusOnline(null);
		
		room -= this;
	}

	// Al establecer la conexión
	void onConnect() {
		//writefln("[1]");
		Packet packet = new Packet(GAME_PACKET.LOGIN);
		packet.write(loginSeed = rand());
		//writefln("[2]");
		send(packet);		
		//writefln("[3]");
	}

	// Al haberse logueado satisfactoriamente
	void onLogin() {
		//writefln("[4]");
		character.server.sendStatusOnline(this);

		{
			Packet sp = new Packet(GAME_PACKET.INFO);
			sp.write(cast(ulong)character.id);
			//if (rem) {
			if (false) {
				sp.writeStringLen16("stars");
			} else {
				sp.writeStringLen16("dojo");
			}

			send(sp);
		}

		server.sendAll(character.genPacketCreateCharacter());

		foreach (client; server.gclist.list) {
			if (client == this) continue;
			send(client.character.genPacketCreateCharacter());
		}

		foreach (chara; server.elist.list) {
			send((cast(Character)chara).genPacketCreateCharacter());
		}
		
		server.onConnected(this, null);
		//writefln("[5]");
	}

	// Enviamos un paquete de ping
	void sendPing() {
		Packet packet = new Packet(GAME_PACKET.PING);
		packet.write(pingTime = globalMili);
		send(packet);
		ping = false;
	}

	void onTick() {
		if (status == GAME_PACKET.LOGIN) return;
		if (tick % 10000 == 0) sendPing();
		if (tick % 10000 == 10000 - 1 && !ping) remove = true;
		tick++;
	}

	void processPacketStatusConnected(Packet p) {		
		switch (p.id) {
			// Paquete que envía al cliente cuando desea hacer login
			case GAME_PACKET.LOGIN:
				char[] user, pass;
				char[] expectedHash = md5(format("%s%d", md5("password"), loginSeed));
				p.readStringLen16(user);
				p.readStringLen16(pass);

				//writefln("Usuario '%s' logueado con hash '%s'", user, pass);
				//writefln("Hash esperado '%s'", expectedHash);

				if (pass == expectedHash) {
					//writefln("Correcto");
					status = Status.loged;
					onTick();
					onLogin();
				} else {
					//writefln("Usuario/contraseña inválidas");
				}
			break;
		}
	}

	void processPacketStatusLoged(Packet p) {
		switch (p.id) {
			case GAME_PACKET.LOGOUT:
				remove = true;
			break;
			// Paquete que envía el cliente cuando desea enviar un texto a otros personajes
			case GAME_PACKET.CHAT:
				char[] text;
				p.readStringLen16(text);
				//writefln("El usuario ha dicho: '%s'", text);
				if (text.length) {
					Packet sp = new Packet(GAME_PACKET.CHAT);
					sp.write(cast(ulong)character.id);
					sp.writeStringLen16(character.name);
					sp.writeStringLen16(text);
					character.server.sendAll(sp);
					if (room) room.onSay(this, new TextEventArgs(text));
				}
			break;
			// Paquete que envía el cliente para iniciar un movimiento
			case GAME_PACKET.MOVING: {
				s64 time;
				p.read(time);
				p.read(character.x);
				p.read(character.y);
				p.read(character.dx);
				p.read(character.dy);
				p.read(character.vx);
				p.read(character.vy);

				Packet sp = new Packet(GAME_PACKET.MOVING); {
					sp.write(cast(ulong)character.id);
					sp.write(time - diffTime);
					sp.write(character.x);
					sp.write(character.y);
					sp.write(character.dx);
					sp.write(character.dy);
					sp.write(character.vx);
					sp.write(character.vy);
					sp.write(character.busy);
					character.server.sendAll(sp, this);
				}

				//writefln("Moving");
			}
			break;
			// Paquete que envía el cliente como respuesta de un ping del servidor
			// Este paquete se utiliza para sincronizar los tiempos entre cliente y servidor
			// para la interpolación de movimientos.
			case GAME_PACKET.PING: {
				u64 clientTime;
				p.read(clientTime);
				diffTime = clientTime - pingTime;
				ping = true;
			} break;
			// No sabemos procesar el paquete
			default:
				writefln("Unexpected packet %02X[%d] in status Connected", p.id, p.available);
			break;
		}
	}

	void processPackets() {		
		try {
			while (packetAvailable) {
				//writefln("[process]");
				Packet packet = recv();				
				switch (status) {
					case Status.connected: processPacketStatusConnected(packet); break;
					case Status.loged:     processPacketStatusLoged(packet);     break;
				}
			}
		} catch (Exception e) {
			writefln("Exception: %s", e.toString());
			remove = true;
		}
	}
	
	void close() {
		socket.close();
		this.onClose();
	}
}

class ClientList : TEntryList!(Client) { }
class EntityList : TEntryList!(Entity) { }

class Server {
	TcpSocket listener;
	SocketSet checkRead, checkWrite, checkError;
	ClientList gclist;
	ClientList[Point] gclistbox;
	EntityList elist;
	EntityList[Point] elistbox;
	static const int gclistboxsize = 150;
	//Sqlite3 gamedb;

	char[] motd =
		"<font color=\"#00007f\"><b>Implementadas colisiones de líneas.</b></font>\n"
	;

	this(char[] ip = "0.0.0.0", ushort port = 8080) {
		// Crea un socket TCP para escuchar
		listener = new TcpSocket();
		listener.blocking = false;

		try {
			// Pone al socket a escuchar en la ip y puetos especificados
			listener.bind(new InternetAddress(ip, port));
			listener.listen(512);
		} catch (Exception e) {
			throw(new Exception(std.string.format("Can't listen at %s:%d", ip, port)));
		}

		checkRead  = new SocketSet();
		checkWrite = new SocketSet();
		checkError = new SocketSet();
		gclist     = new ClientList;
		elist      = new EntityList();

		//writefln("Using Sqlite %s", Sqlite3.libVersion);
		//gamedb = new Sqlite3("db/game.db");
		//Card.updateDatabase(gamedb);
	}

	~this() {
		listener.close();
		//delete gamedb; gamedb = null;
	}
	
	void stop() {
		foreach (c; gclist.list) c.close();
		this.listener.close();
	}

	void sendStatusOnline(Client zclient = null) {
		Packet sp = new Packet(GAME_PACKET.CHAT);
		char[] sendtext = "";
		char[] pl = (gclist.length != 1) ? "s" : "";
		sendtext ~= std.string.format("<i>Actualmente hay <b>%d</b> usuario%s conectado%s</i> (", gclist.length, pl, pl);
		int count = 0;
		foreach (client; gclist.list) {
			if (count != 0) sendtext ~= ", ";
			sendtext ~= "<b>" ~ client.socket.remoteAddress().toString() ~ "(" ~ client.character.name ~ ")</b>";
			//sendtext ~= "<b>" ~ client.character.name ~ "</b>";
			count++;
		}
		sendtext ~= ")";

		sp.write(cast(ulong)0);
		sp.writeStringLen16("");
		sp.writeStringLen16(sendtext);
		sendAll(sp);

		if (zclient !is null) {
			sp = new Packet(GAME_PACKET.CHAT);
			sp.write(cast(ulong)0);
			sp.writeStringLen16("MOTD");
			sp.writeStringLen16(motd);
			zclient.send(sp);
		}
	}

	// Envía un paquete especificado a todos los clientes del juego cercanos a otro cliente
	void sendAllNear(Packet p, Client gc, Client except = null, int radius = gclistboxsize) {
		int xbox = gc.character.xbox, ybox = gc.character.ybox; Point cp;
		int rbox = cast(int)std.math.ceil(cast(double)radius / cast(double)gclistboxsize);

		for (cp.y = xbox - rbox; cp.y <= xbox + rbox; cp.y++) {
			for (cp.x = xbox - rbox; cp.x <= xbox + rbox; cp.x++) {
				if ((cp in elistbox) is null) continue;
				foreach (client; gclistbox[cp].list) {
					if (client == except) continue;
					client.send(p);
				}
			}
		}
	}

	// Envía un paquete especificado a todos los clientes del juego excepto a uno (opcional)
	void sendAll(Packet p, Client except = null) {
		foreach (client; gclist.list) {
			if (client == except) continue;
			client.send(p);
		}
	}

	void killClient(Client client) {
		gclist.remove(client);
		client.onClose();
		delete client;
	}

	void mainLoop() {
		checkRead.reset();
		checkRead.add(listener);
		//foreach (client; gclist.list) checkRead.add(client.socket);

		try {
			listener.select(checkRead, checkWrite, checkError, 1);

			if (checkRead.isSet(listener)) {
				Client client = new Client(listener.accept(), this);				
				gclist.add(client);
			}
		} catch (Exception e) {
			.writefln("ERROR: %s", e.toString);
		}

		foreach (client; gclist.list) {
			if (!client.isAlive || client.remove) {
				killClient(client);
				continue;
			}

			try {
				client.processPackets();
				client.onTick();
			} catch (Exception e) {
				writefln("Exception: %s", e.toString());
				killClient(client);
			}
		}
	}
	
	void init() {		
	}
	
	Event!(Client, EventArgs) onConnected;
}

Room[char[]] rooms;

// Clase encargada de almacenar información sobre habitaciones
class Room {
	Server server;
	ClientList gclist;
	char[] id, type;

	// Constructor; añadimos la habtiación actual a la lista de habitaciones
	this(char[] id, char[] type = "") {
		this.server = .server;
		this.type = type;
		gclist = new ClientList();
		rooms[this.id = id] = this;
	}
	
	// Destructor; quitamos la habitación actual de la lista de habitaciones
	~this() {
		rooms.remove(this.id);
	}
	
	// Añadimos un cliente a la habitación
	void opAddAssign(Client gc) {
		if (!gclist.has(gc)) {
			if (gc.room) gc.room -= gc;		
			gclist += gc;
			gc.room = this;
		}
		
		onEnter(gc, null);
	}
	
	// Eliminamos un cliente de la habitación
	void opSubAssign(Client gc) {
		if (gclist.has(gc)) {
			gclist -= gc;
			gc.room = null;
		}
		
		onLeave(gc, null);
	}
	
	Event!(Client, EventArgs) onEnter;
	Event!(Client, EventArgs) onLeave;
	Event!(Client, TextEventArgs) onSay;
}

void scriptingStartServer() {
	// Creamos la habitación principal
	Room room = new Room("main");
	Room room2 = new Room("dojo");
	
	room.onEnter ~= delegate(Client client, EventArgs ea) {	
		writefln("Room.onEnter()");
		rem.say("Bienvenido joven espíritu. Soy Rem, <font color='#ff0000'>diosa de la luz</font>.\nHabla conmigo y te diré todo lo que necesitas saber.");
	};

	room.onLeave ~= delegate(Client client, EventArgs ea) {	
		writefln("Room.onLeave()");
	};

	/*room.onSay ~= delegate(Client client, TextEventArgs tea) {
	};*/
	
	room.onSay ~= delegate(Client client, TextEventArgs tea) {
		writefln("Room.onSay() -> %s", tea.s);
		switch (std.string.tolower(std.string.strip(tea.s))) {
			case "hola":
				rem.say("Hola, joven espíritu");
			break;
			case "¿quién eres?":
				rem.say("Soy Rem, <font color='#ff0000'>diosa de la luz</font>.");
			break;
			case "¿cuál es tu función?":
			case "¿qué quieres?":
			case "¿qué haces?":
			case "¿qué haces aquí?":
				rem.say("Me encargo de guiar a los espíritus al mundo material.");
			break;
			case "¿porqué?": case "¿por qué?":
				rem.say("Hay cosas que están fuera del entendimiento de los espíritus y de los humanos.");
			break;
			default:
				rem.say(std.string.format("No entiendo que quieres decir, %s", client.character.name));
			break;
		}
	};

	/*room2.onSay ~= delegate(Client client, TextEventArgs tea) {
		switch (std.string.tolower(std.string.strip(tea.s))) {
			case "teleport":
				rooms["dojo"] -= client;
				rooms["main"] += client;

				client.send(rem.genPacketRemoveCharacter);
				client.send(ram.genPacketRemoveCharacter);
				
				scope sp = new Packet(GAME_PACKET.INFO);
				sp.write(cast(ulong)client.character.id);
				sp.writeStringLen16("main");
				client.send(sp);
			break;
		}
	};*/

	room.onSay ~= delegate(Client client, TextEventArgs tea) {
		switch (std.string.tolower(std.string.strip(tea.s))) {
			case "hola":
				ram.say("Hi");
			break;
			case "¿quién eres?":
				ram.say("¿Y a ti que te importa?");
			break;
			case "¿cuál es tu función?":
			case "¿qué quieres?":
			case "¿qué haces?":
			case "¿qué haces aquí?":
				ram.say("Me encargo de hacer el cabra por aquí.");
			break;
			case "¿porqué?": case "¿por qué?":
			break;
			/*
			case "teleport":
				rooms["main"] -= client;
				rooms["dojo"] += client;

				client.send(rem.genPacketRemoveCharacter);
				client.send(ram.genPacketRemoveCharacter);
				
				scope sp = new Packet(GAME_PACKET.INFO);
				sp.write(cast(ulong)client.character.id);
				sp.writeStringLen16("dojo");
				client.send(sp);
			break;
			*/
			default:
				ram.say("dejadme tranquila");
			break;
		}
	};
	
	server.onConnected ~= delegate(Client client, EventArgs ea) {	
		writefln("Server.onConnected");
		rooms["main"] += client;
	};
	
	rem = new Character("Rem", "rem");
	rem.server = server;
	rem.move(520, 310);
	rem.type = 1;
	server.elist.add(rem);
	rem.sizex = rem.sizey = 1.2;
	
	ram = new Character("Farah", "farah");
	ram.server = server;
	ram.move(480, 330);
	ram.type = 1;
	server.elist.add(ram);
	ram.sizex = ram.sizey = 0.8;	
}

version (Windows) {
	const uint CTRL_C_EVENT = 0;
	const uint CTRL_BREAK_EVENT = 1;
	const uint CTRL_CLOSE_EVENT = 2;
	const uint CTRL_LOGOFF_EVENT = 5;
	const uint CTRL_SHUTDOWN_EVENT = 6;

	extern(C) bool CtrlHandler(uint fdwCtrlType) {
		switch (fdwCtrlType) {
			case CTRL_C_EVENT: 
			case CTRL_CLOSE_EVENT: 
			case CTRL_BREAK_EVENT: 
			case CTRL_LOGOFF_EVENT: 
			case CTRL_SHUTDOWN_EVENT: 
			default:
			
			writef("Cerrando...");
			server.stop();			
			writefln("Ok");
			
			return false;
		} 
	}

	extern(C) typedef bool function(uint) PHANDLER_ROUTINE;

	extern(Windows) bool SetConsoleCtrlHandler(PHANDLER_ROUTINE, bool);
}

Character rem, ram;
Server server;

int main(char[][] args) {
	int tick = 0;
	server = new Server();
	
	version (Windows) SetConsoleCtrlHandler(&CtrlHandler, true);
	
	scriptingStartServer();
	
	server.init();

	try {
		writefln("Game Server initialized");

		while (true) {
			globalMili = cast(s64)GetMili();
			//printf("%d\n", cast(int)globalMili);
			try {
				server.mainLoop();
			} catch (Exception e) {
				writefln("s: %s", e.toString);
			}
			Rest();
			if (++tick % 10 == 0) Rest1();
		}
	} finally {
		delete server;
	}

	return 0;
}
