public import std.stdio, std.math, std.conv, std.socket, std.socketstream, std.stream, std.md5, std.string;
public import std.c.time, std.random;

/*
public import tango.io.device.Array;
public import tango.net.device.Socket;

class MemoryStream {
	void write(T)(T v) {
	}

	void read(T)(ref T v) {
	}
}

class TcpSocket {
}*/

char[] md5(void[] data) {
	MD5_CTX context;
	ubyte[16] digest;
	context.start();
	context.update(data);
	context.finish(digest);
	return digestToString(digest);
}

/*
uint rand() {
	return 0;
}

char[] format(char[] args, ...) {
	return "";
}

char[] writefln(char[] args, ...) {
	return "";
}*/