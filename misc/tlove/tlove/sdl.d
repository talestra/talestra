module sdl;

import std.c.windows.windows;
import std.stdio;

template SDL_Imports() { public extern (C) static:
	void function(uint flags = 0) SDL_Init;
	SDL_Surface* function(int width, int height, int bitsperpixel = 0, uint flags = 0) SDL_SetVideoMode;
	int function(SDL_Surface* screen) SDL_Flip;
	int function(SDL_Event *event) SDL_PollEvent;
	void function() SDL_PumpEvents;
	void function(uint ms) SDL_Delay;
	SDL_Surface* function(uint flags, int width, int height, int bitsPerPixel, uint Rmask = 0, uint Gmask = 0, uint Bmask = 0, uint Amask = 0) SDL_CreateRGBSurface;
	int function(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect) SDL_UpperBlit;
	int function(SDL_Surface *surface, SDL_Color *colors, int firstcolor, int ncolors) SDL_SetColors;
	int function(SDL_Surface *dst, SDL_Rect *dstrect, uint color) SDL_FillRect;
	ubyte function(int* x, int* y) SDL_GetMouseState;
	int function(SDL_Surface* surface, uint flag, uint key) SDL_SetColorKey;
	void function(SDL_Surface* surface) SDL_FreeSurface;
}

template IMG_Imports() { public extern (C) static:
	int function(int flags = 0) IMG_Init;
	SDL_Surface* function(char* file) IMG_Load;
}

template TTF_Imports() { public extern (C) static:
	int function() TTF_Init;
	TTF_Font* function(char* file, int ptsize) TTF_OpenFont;
	SDL_Surface* function(TTF_Font* font, char* text, SDL_Color fg) TTF_RenderText_Solid;
}

mixin SDL_Imports;
mixin IMG_Imports;
mixin TTF_Imports;

struct TTF_Font;


enum {
	SDL_QUIT = 12,
}

void SDL_ProcessEvents() {
	SDL_Event event;
	while (SDL_PollEvent(&event)) {
		switch (event.type) {
			case SDL_QUIT:
				throw(new Exception("Quit!"));
			default:
			break;
		}
	}
}

alias SDL_UpperBlit SDL_BlitSurface;

struct SDL_Event {
	ubyte type;
	ubyte[32] dummy;
}

struct SDL_Surface {
	uint flags;
	SDL_PixelFormat* format;
	int w, h;
	ushort pitch;
	void* pixels;
	SDL_Rect clip_rect;
	int refcount;
}

struct SDL_Rect { short x, y; ushort w, h; }

struct SDL_PixelFormat {
	SDL_Palette* palette;
	ubyte  BitsPerPixel;
	ubyte  BytesPerPixel;
	ubyte  Rloss, Gloss, Bloss, Aloss;
	ubyte  Rshift, Gshift, Bshift, Ashift;
	uint   Rmask, Gmask, Bmask, Amask;
	uint   colorkey;
	ubyte  alpha;
}

struct SDL_Palette{ int ncolors; SDL_Color* colors; }

struct SDL_Color { ubyte r, g, b, a; }

void SDL_CopyPalette(SDL_Surface* src, SDL_Surface* dst) {
	if (src && src.format && src.format.palette) SDL_SetColors(dst, src.format.palette.colors, 0, src.format.palette.ncolors);
}

void SDL_DelayEvents(int ms) {
	SDL_ProcessEvents();
	while (ms-- > 0) {
		SDL_ProcessEvents();
		SDL_Delay(1);
	}
}

static this() {
	BindLibrary!("SDL.dll", SDL_Imports);
	BindLibrary!("SDL_image.dll", IMG_Imports);
	BindLibrary!("SDL_ttf.dll", TTF_Imports);
}

void BindLibrary(string dll, alias bindTemplate, string prefixTo = "", string prefixFrom = "")() {
	HANDLE lib = LoadLibraryA(dll);
	if (lib is null) throw(new Exception("Can't load library '" ~ dll ~ "'"));
	
	static string ProcessMember(string name) {
		string dname = prefixTo ~ name;
		string importName = prefixFrom ~ name;
		return (
			"{ static if (__traits(compiles, &" ~ dname ~ ")) {"
				"void* addr = cast(void*)GetProcAddress(lib, \"" ~ importName ~ "\");"
				"if (addr is null) throw(new Exception(\"Can't load '" ~ importName ~ "' from '" ~ dll ~ "'\"));"
				"*cast(void**)&" ~ dname ~ " = addr;"
			"} }"
		); 
	}
	
	static string ProcessMembers(alias T)() {
		string s;
		static if (T.length >= 1) {
			s ~= ProcessMember(T[0]);
			static if (T.length > 1) s ~= ProcessMembers!(T[1..$])();
		}
		return s;
	}

	mixin(ProcessMembers!(__traits(derivedMembers, bindTemplate))());
}