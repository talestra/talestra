import std.stdio, std.stream, std.c.windows.windows, std.string, std.system, std.variant, std.random;
import sdl;

static pure nothrow string tos(T)(T v, int base = 10, int pad = 0) {
	if (v == 0) return "0";
	const digits = "0123456789abcdef";
	assert(base <= digits.length);
	string r;
	long vv = cast(long)v;
	bool sign = (vv < 0);
	if (sign) vv = -vv;
	while (vv != 0) {
		r = digits[cast(uint)(vv) % base] ~ r;
		vv /= base;
	}
	while (r.length < pad) r = '0' ~ r;
	if (sign) r = "-" ~ r;
	return r;
}


ubyte read1(Stream stream) { ubyte v; stream.read(v); return v; }
ushort read12ex(Stream stream) {
	ubyte[2] v;
	stream.read(v[0]);
	if (v[0] & 0x80) {
		stream.read(v[1]);
		return ((v[0] & 0x7F) << 8) | v[1];
	} else {
		return v[0];
	}
}
ushort read2(Stream stream) {
	ubyte[2] v;
	stream.read(v);
	return (v[0] << 8) | v[1];
}
string readStringz(Stream stream) {
	char c;
	string s;
	while (!stream.eof) {
		stream.read(c);
		if (c == 0) break;
		s ~= c;
	}
	return s;
}
Stream readSlice(Stream stream, uint len) {
	auto v = new SliceStream(stream, stream.position, stream.position + len);
	stream.seekCur(len);
	return v;
}


class PAK {
	void load(Stream stream) {
		
	}
}

class DAT {
	Stream stream;
	ushort[] labels;
	
	void load(Stream stream) {
		stream = new MemoryStream(cast(ubyte[])(new SliceStream(stream, 0, stream.size)).readString(cast(uint)stream.size));
		ushort scriptStart = read2(stream);
		labels.length = (scriptStart - 2) / 2;
		foreach (ref label; labels) label = read2(stream);
		this.stream = new SliceStream(stream, scriptStart, stream.size);
	}
}

//alias ushort Label;
typedef ushort Label;

class Game {
	DAT dat;
	Opcodes opcodes;
	ubyte[256][4] flags;
	//int[256][4] flags;
	SDL_Surface*[6] buffers;
	struct ExecutionContext {
		string file;
		uint pos;
	}
	
	ExecutionContext currentExecutionContext;
	ExecutionContext[] executionStack;

	class Opcodes {
		/**
		 * Loads an image in a buffer
		 *
		 * @param  fileName  File to load
		 * @param  bufferId  Buffer to load the image
		 */
		void IMAGE_LOAD(string name, ubyte buffer) {
			writefln("IMAGE_LOAD('%s', %d)", name, buffer);
			auto image = IMG_Load(cast(char*)("MRS.d/" ~ name ~ ".MRS.PNG\0").ptr);

			SDL_CopyPalette(image, buffers[buffer]);
			SDL_BlitSurface(image, null, buffers[buffer], null);
		}

		/**
		 * Copy an slice of buffer into another
		 *
		 */
		void IMAGE_COPY(ubyte time, ubyte color_key, ubyte src_buffer, ushort src_x, ushort src_y, ushort src_w, ushort src_h, ubyte dst_buffer, ushort dst_x = 0, ushort dst_y = 0, ushort u1 = 0, ushort u2 = 0, ushort u3 = 0) {
			writefln(
				"IMAGE_COPY Time(%2d) ColorKey(%d) Buffer[%d](%3d, %3d, %3d, %3d) -> Buffer[%d](%3d, %3d) Unknown(%d, %d, %d)",
				time, color_key,
				src_buffer, src_x, src_y, src_w, src_h,
				dst_buffer, dst_x, dst_y,
				u1, u2, u3
			);

			scope src = SDL_Rect(src_x, src_y, src_w, src_h);
			scope dst = SDL_Rect(dst_x, dst_y, src_w, src_h);

			SDL_CopyPalette(buffers[src_buffer], buffers[dst_buffer]);
			if (time) SDL_SetColorKey(buffers[src_buffer], 0x00001000, color_key);
			SDL_BlitSurface(buffers[src_buffer], &src, buffers[dst_buffer], &dst);
			SDL_SetColorKey(buffers[src_buffer], 0, 0);
		}
		
		void CALL(Label label) {
			writefln("CALL:%04X", label);
			executionStack ~= currentExecutionContext;
			currentExecutionContext.pos = dat.labels[label];
			writefln("-->%s", currentExecutionContext);
		}

		void JUMP(Label label) {
			writefln("JUMP:%04X", label);
			currentExecutionContext.pos = dat.labels[label];
		}

		void JUMP_IF(ubyte flag, ubyte op, ushort imm, Label label) {
			writefln("JUMP_IF(%d, %d, %d, %d)", flag, op, imm, label);
			bool result = false;
			switch (op) {
				case 0: result = (flagGet(2, flag) <= imm); break;
				case 1: result = (flagGet(2, flag) == imm); break;
				default:
				case 2: result = (flagGet(2, flag) >= imm); break;
			}
			if (result) JUMP(label);
		}
		
		void RETURN() {
			auto lastFile = currentExecutionContext.file;
			currentExecutionContext = executionStack[$ - 1];
			executionStack.length = executionStack.length - 1;
			writefln("<--%s", currentExecutionContext);
			if (lastFile != currentExecutionContext.file) {
				dat.load(new std.stream.File("DATE.d/" ~ currentExecutionContext.file ~ ".DAT"));
			}
		}
		
		void FILL_RECT(ubyte color, ubyte extra, ushort x, ushort y, ushort w, ushort h) { // T_LOVE95.EXE:40B9F0
			ubyte type  = (extra & 3);
			ubyte param = cast(ubyte)(extra >> 2);
			writefln("RECT((%d, %d, %d)%d, %d, %d, %d)", color, type, param, x, y, w, h);
			switch (type) {
				case 0: { // Normal fill rect
					scope dst = SDL_Rect(x, y, w, h);
					SDL_FillRect(buffers[0], &dst, color);
				} break;
				
			}
		}

		void MUSIC_PLAY(string name, ushort loop) {
			writefln("MUSIC_PLAY('%s', %d)", name, loop);
		}
		
		void MUSIC_STOP() {
			writefln("MUSIC_STOP()");
		}
		
		void DELAY(ushort frames) {
			writefln("DELAY(%d)", frames);
			//SDL_DelayEvents(frames * 20);
		}
		
		void UPDATE() { // FLIP?
			writefln("UPDATE()");
			SDL_Flip(buffers[0]);
		}
		
		void FLAG_SET(ubyte flag_type, ushort flag_num, ubyte value) {
		}
		
		void FLAG_SET_RANGE(ubyte flag_type, ushort from, ushort count, ubyte value) {
			writefln("FLAG_SET_RANGE(FLAGS[%d][%d..%d] = %d)", flag_type, from, from + count, value);
			for (ushort n = from; n < from + count; n++) {
				FLAG_SET(flag_type, n, value);
			}
		}
		
		void SCRIPT_SET(string name, ubyte _0 = 0) {
			writefln("SCRIPT_SET('%s')", name);
			currentExecutionContext.file = name;
			currentExecutionContext.pos = 0;
			dat.load(new std.stream.File("DATE.d/" ~ name ~ ".DAT"));
		}

		void SCRIPT_CALL(string name, ubyte _0 = 0) {
			writefln("SCRIPT_CALL('%s')", name);
			executionStack ~= currentExecutionContext;
			SCRIPT_SET(name);
		}
		
		void PALETTE(ubyte op, ubyte index, ubyte r, ubyte g, ubyte b) {
			switch (op) {
				case 0: // Set palette entry
				break;
				case 1: // Use current palette
				break;
				case 2:
				break;
				case 4:
				break;
				case 5: // Palette copy (r -> g)
				break;
			}
		}
		
		void WAIT_CLICK(Label labelLeftClick, Label labelRightClick) {
			while (true) {
				mouseState.updateMouse();
				if (mouseState.left ) { JUMP(labelLeftClick ); break; }
				if (mouseState.right) { JUMP(labelRightClick); break; }
				//writefln("%08b", buttons);
				SDL_DelayEvents(20);
			}
		}

		void ANI_LOAD(string name, ubyte n) {
			//local mrs = ::MRS(::pak_mrs[name + ".MRS"]);
			//current_ani = mrs.anims[n];
			writefln("ANI_LOAD('%s', %d)", name, n);
		}

		void ANI_PLAY(ubyte y, ubyte x, ubyte _ff) {
			writefln("ANI_PLAY(%d, %d)(%d)\n", x, y, _ff);
			//current_ani_info = {x=x, y=y, t=_ff};
			//current_ani_time = 0;
			//current_ani_last_idx = -1;
		}
	
		struct MouseState {
			int x, y;
			ubyte buttons, lastButtons;
			Label labelLeftClick;
			Label labelRightClick;
			Label labelMiss;
			ubyte count;
			bool left () { return (buttons & 1) && !(lastButtons & 1); }
			bool right() { return (buttons & 4) && !(lastButtons & 4); }
			void updateMouse() {
				lastButtons = buttons;
				buttons = SDL_GetMouseState(&x, &y);
			}
			bool inRect(int x1, int y1, int x2, int y2) {
				return (x >= x1 && x <= x2) && (y >= y1 && y <= y2);
			}
		}
		
		MouseState mouseState;

		void JUMP_MOUSE_IN(ushort x1, ushort y1, ushort x2, ushort y2, Label label) {
			if (mouseState.inRect(x1, y1, x2, y2)) {
				JUMP(label);
			}
		}

		void JUMP_IF_MOUSE_START(Label labelLeftClick, Label labelRightClick, Label labelMiss, ubyte count) {
			writefln("JUMP_IF_MOUSE_START(%d, %d, %d, %d)", labelLeftClick, labelRightClick, labelMiss, count);
			//mouseState.updateMouse();
			mouseState.labelLeftClick = labelLeftClick;
			mouseState.labelRightClick = labelRightClick;
			mouseState.labelMiss = labelMiss;
			mouseState.count = count;
			SDL_DelayEvents(0);
			mouseState.updateMouse();
		}

		void JUMP_IF_MOUSE_IN(ushort x1, ushort y1, ushort x2, ushort y2, Label label, ubyte flag_type, ushort flag) {
			writefln("JUMP_IF_MOUSE_IN((%d, %d)-(%d, %d)) label_%04X flags[%d][%d]", x1, y1, x2, y2, label, flag_type, flag);
			if (mouseState.left) {
				if (mouseState.inRect(x1, y1, x2, y2)) {
					//if (flagGet(flag_type, flag))
					{
						JUMP(label);
						return;
					}
				}
			}
			if (--mouseState.count <= 0) {
				if (mouseState.left) {
					JUMP(mouseState.labelLeftClick);
				} else if (mouseState.right) {
					JUMP(mouseState.labelRightClick);
				} else { // None
					JUMP(mouseState.labelMiss);
				}
			}
		}
	}
	
	ubyte flagGet(int type, int index) {
		return flags[type][index];
	}
	
	void flagSet(int type, int index, int value) {
		flags[type][index] = cast(ubyte)value;
	}
	
	void executeSingle() {
		ubyte opcode;
		ushort len;
		Stream params;
		dat.stream.position = currentExecutionContext.pos;
		{
			opcode = read1(dat.stream);
			len    = read12ex(dat.stream);
			params = readSlice(dat.stream, len);
		}
		currentExecutionContext.pos = cast(uint)dat.stream.position;

		// Macros for reading parameters.
		string str() { return readStringz(params); }
		ubyte  i1() { return read1(params); }
		ushort i2() { return read2(params); }
		Label label() { return cast(Label)read2(params); }
		bool more() { return !params.eof; }
		
		switch (opcode) {
			case 0x17: // ?
				opcodes.UPDATE();
			break;
			case 0x28: // </ id=0x28, format="2", description="Jumps to an adress" />
				opcodes.JUMP(label);
			break;
			case 0x2B: // </ id=0x2B, format="2", description="Calls to an adress" />
				opcodes.CALL(label);
			break;
			case 0x33: // </ id=0x33, format="s1", description="Loads an image in a buffer" />
				opcodes.IMAGE_LOAD(str, i1);
			break;
			case 0x36: // </ id=0x36, format="1112222122222", description="Copy an slice of buffer into another" />
				opcodes.IMAGE_COPY(
					i1, i1,
					i1, i2, i2, i2, i2,				
					i1, i2, i2,
					i2, i2, i2
				);
			break;
			case 0x38: // </ id=0x38, format="s1", description="Load an animation" />
				opcodes.ANI_LOAD(str, i1);
			break;
			case 0x53: // </ id=0x53 format="111", description="Ani play" />
				opcodes.ANI_PLAY(i1, i1, i1);
			break;
	
			case 0x3A: // </ id=0x3A, format="22222", description="Fills a rect" />
				opcodes.FILL_RECT(i1, i1, i2, i2, i2, i2);
			break;
			case 0x3C: // </ id=0x3A, format="11111", description="Performs an operation with palettes" />
				opcodes.PALETTE(i1, i1, i1, i1, i1);
			break;
			case 0x44: // </ id=0x44, format="1122", description="Jumps conditionally" />
				opcodes.JUMP_IF(i1, i1, i2, label);
			break;
			case 0x61: // </ id=0x61, format="s2", description="Plays a midi file" />
				opcodes.MUSIC_PLAY(str, i2);
			break;
			case 0x63: // </ id=0x63, format="", description="Music stop" />
				opcodes.MUSIC_STOP();
			break;
			case 0x70: { // </ id=0x70, format="?", description="Put text (dialog)" />
				int[6] v;
				string text;
				try {
					v[0] = i1;
					v[1] = i1;
					v[2] = i1;
					if (v[2] != 0xFF) {
						v[3] = i1;
						v[4] = i1;
						v[5] = i1;
					}
					while (more) text ~= str;
				} catch {
				}

				auto textBmp = TTF_RenderText_Solid(font, cast(char*)(text ~ "\0").ptr, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));
				auto rect = SDL_Rect(24, 332, 100, 100);
				SDL_BlitSurface(textBmp, null, buffers[0], &rect);
				SDL_FreeSurface(textBmp);

				writefln("text:%s", text);
			} break;
			case 0x71: { // </ id=0x71, format="221s", description="Put text (y, x, ?color?, text, ??)" />
				auto x = i2;
				auto y = i2;
				auto color = i2;
				auto text = str;
				
				auto textBmp = TTF_RenderText_Solid(font, cast(char*)(text ~ "\0").ptr, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));
				auto rect = SDL_Rect(x, y, 100, 100);
				SDL_BlitSurface(textBmp, null, buffers[0], &rect);
				SDL_FreeSurface(textBmp);

				writefln("text2:'%s'", text);
			} break;
			case 0x89: // </ id=0x89, format="2", description="Delay" />
				opcodes.DELAY(i2);
			break;
			case 0x8A: // </ id=0x8A, format="", description="Updates" />
				opcodes.UPDATE();
			break;
			case 0x95: // </ id=0x95, format="1221", description="Sets a range of flags" />
				opcodes.FLAG_SET_RANGE(i1, i2, i2, i1);
			break;
			case 0x52: // </ id=0x52, format="s1", description="Loads a script and starts executing it" />
				opcodes.SCRIPT_CALL(str, i1);
			break;
			case 0x91: // </ id=0x91, format="", description="Return from a CALL" />
				opcodes.RETURN();
			break;
			case 0x98: { // </ id=0x98, format="?", description="Sets a flag" />
				int lvalue, rvalue, zvalue;
				int op_pos = 0;
				auto flag = i2;
				assert(flag & 0x8000);

				int getValue(int v) {
					if ((v & 0xC000) == 0xC000) {
						auto rnd = Random(unpredictableSeed);
						rnd.popFront();
						return rnd.front % (v & 0x3FFF);
					}
					if (v & 0x8000) return flagGet(2, v & 0x7FFF);
					return v;
				}
				
				while (!more) {
					ubyte op = i1;
					if (op == 4) break;

					if (op == 0x08) {
						op = 0x00;
						zvalue = i2;
					} else {
						zvalue = getValue(i2);
					}

					if (op_pos++ & 2) {
						switch (op) {
							case 0x00: rvalue  = zvalue; break; // Add?
							case 0x01: rvalue -= zvalue; break; // Substract?
							case 0x02: rvalue *= zvalue; break; // Multiply?
							case 0x03: try { rvalue /= zvalue; } catch { } break; // Divide?
						}
					} else {
						switch (op) {
							case 0x00: lvalue += zvalue; break; // Add?
							case 0x01: lvalue -= zvalue; break; // Substract?
							case 0x02: lvalue += rvalue * zvalue; rvalue = 0; break; // Multiply?
							case 0x03: try { lvalue += rvalue / zvalue; } catch { } rvalue = 0; break; // Divide?
						}
					}
				}
				
				flagSet(0, flag & 0x7FFF, lvalue + rvalue);
			} break;
			case 0xA6: // </ id=0xA6, format="22", description="Wait?" />
				opcodes.WAIT_CLICK(label, label);
			break;
			case 0xA7: { // </ id=0xA7, format="22222", description="" />
				opcodes.JUMP_MOUSE_IN(i2, i2, i2, i2, label);
			} break;
			case 0xAD: // </ id=0xAD, format="2221", description="" />
				opcodes.JUMP_IF_MOUSE_START(label, label, label, i1);
			break;
			case 0xAE: // </ id=0xAE, format="22 22 212", description="" />
				opcodes.JUMP_IF_MOUSE_IN(i2, i2, i2, i2, label, i1, i2);
			break;
			// </ id=0x9D, format="2", description="????" />
			case 0x9D, 0x85, 0x73, 0x72, 0x83, 0x35, 0x30, 0x49, 0x82, 0x86, 0x23, 0x54, 0x24, 0x19, 0x75, 0x31, 0x4D, 0x32, 0x99, 0x41, 0x1B, 0x34, 0x48, 0x4C, 0x92, 0x39, 0x40, 0x94, 0x45:
				writefln("Unprocessed: 0x%02X: %d", opcode, len);
			break;
			// Ignore.
			case 0x84, 0x16, 0x87: // INTERFACE: 'WIN', 'WIN', 'CMK'
				//format("s");
			break;
			case 0xFF:
				throw(new Exception("Game Quit"));
			break;
			default:
				writefln("Unknown: 0x%02X: %d", opcode, len);
				assert(0);
			break;
		}
	}

	void execute() {
		//while (!dat.stream.eof) executeSingle();
		while (true) executeSingle();
	}
	
	TTF_Font* font;

	this() {
		opcodes = new Opcodes;
		dat = new DAT;
		// Initializes SDL_
		SDL_Init();
		IMG_Init();
		TTF_Init();
		font = TTF_OpenFont(cast(char*)"lucon.ttf", 14);

		// Initializes screen.
		buffers[0] = SDL_SetVideoMode(640, 400, 8);
		
		// Create buffers.
		foreach (ref buffer; buffers[1..$]) buffer = SDL_CreateRGBSurface(0, 640, 400, 8);
	}
}

void main() {
	auto game = new Game;
	game.opcodes.SCRIPT_SET("MAIN");
	//game.opcodes.SCRIPT_SET("701");
	game.execute();
}