import std.string, std.stream, std.file, std.stdio, std.regexp, std.math, std.process;

import SDL, SDL_ttf, SDL_mixer, SDL_image, gl, glu;

import npc, ase, util;

extern (C) int putenv(char *);

bool running = true;


bool[SDLK_LAST] keyp;

bool showAxis = false;

void updateInput() {
	static bool dragl = false, dragr = false;
	static float s_angle_x, s_angle_y, s_angle_z;
	static float s_position_x, s_position_y, s_position_z;
	static int sx, sy, mx, my;
	SDL_Event e;
	SDL_GetMouseState(&mx, &my);
	
	for (int n = 0; n < SDLK_LAST; n++) keyp[n] = false;
	
	while (SDL_PollEvent(&e)) {
		switch (e.type) {
			case SDL_QUIT:
				running = false;
			break;
			case SDL_KEYUP:
				/*switch (e.key.keysym.sym) {
					case SDLK_RIGHT: loadVertex1a(+1); break;
					case SDLK_UP: loadVertex1a(+4); break;
					case SDLK_DOWN: loadVertex1a(-4); break;
					case SDLK_LEFT: loadVertex1a(-1); break;
					case SDLK_1: loadVertex1a(0, 3); break;
					case SDLK_2: loadVertex1a(0, 4); break;
					case SDLK_3: loadVertex1a(0, 5); break;
					case SDLK_4: loadVertex1a(0, 6); break;
					default:
				}*/
				keyp[e.key.keysym.sym] = false;
			break;
			case SDL_KEYDOWN:
				keyp[e.key.keysym.sym] = true;
				/*
				break;
				switch (e.key.keysym.sym) {
					case SDLK_LEFT: pos_y -= 10; break;
					case SDLK_RIGHT: pos_y += 10; break;
					case SDLK_UP: pos_x -= 10; break;
					case SDLK_DOWN: pos_x += 10; break;
					case SDLK_PAGEUP: pos_z += 10; break;
					case SDLK_PAGEDOWN: pos_z -= 10; break;
					default:
				}
				*/
			break;
			case SDL_MOUSEBUTTONDOWN:
				switch (e.button.button) {
					case SDL_BUTTON_WHEELUP: dist += dist / 10; break;
					case SDL_BUTTON_WHEELDOWN: dist -= dist / 10; break;
					case SDL_BUTTON_RIGHT:
					case SDL_BUTTON_LEFT:
						if (e.button.button == SDL_BUTTON_LEFT) {
							dragl = true;
						} else {
							dragr = true;
						}
						sx = mx;
						sy = my;
						s_angle_x = angle_x;
						s_angle_y = angle_y;
						s_angle_z = angle_z;

						s_position_x = position_x;
						s_position_y = position_y;
						s_position_z = position_z;
						
						showAxis = true;
					break;
					default: break;
				}
			break;
			case SDL_MOUSEBUTTONUP:
				switch (e.button.button) {
					case SDL_BUTTON_LEFT: dragl = false; showAxis = false; break;
					case SDL_BUTTON_RIGHT: dragr = false; showAxis = false; break;
					default: break;
				}
			break;
			default:
			break;
		}
	}
	if (dragl) {
		angle_y = s_angle_y + ((mx - sx) * dist) / 250;
		angle_x = s_angle_x + ((my - sy) * dist) / 250;
	}
	if (dragr) {
		position_x = s_position_x + ((mx - sx) * dist) / 600;
		position_y = s_position_y - ((my - sy) * dist) / 600;
	}
}

void init() {
	SDL_Init(0);

	// Audio
	if (false) {
		SDL_InitSubSystem(SDL_INIT_AUDIO);
		SDL_mixer.init();
		Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
	}

	// Video
	SDL_InitSubSystem(SDL_INIT_VIDEO);
	putenv("SDL_VIDEO_WINDOW_POS=center");
	putenv("SDL_VIDEO_CENTERED=1");

	/*
    SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );	
	SDL_GL_SetAttribute( 0x2042, 4 );
	*/

	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 8);
	
	SDL_SetVideoMode(width, height, 0, SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_OPENGL);
	//SDL_SetVideoMode(width, height, 0, SDL_OPENGL);

	// Image
	SDL_image.init();
	
	// TTF
	SDL_ttf.init(); TTF_Init();
	
	// opengl
	glInitSystem(); glUsing(2.1); glu.init();
	
	SDL_EnableKeyRepeat(80, 80);
}

NPC chara;

import std.c.windows.windows;

int main(char[][] args) {
	try {
		init();
		
		initScene();
		
		if (args.length > 1) {
			chara = new NPC(new BufferedFile(args[1]));
			//chara.lrpx[0].exportOBJ( new File("out.obj", FileMode.OutNew), new File("out.mtl", FileMode.OutNew));
		} else {
			writefln("Hay que especificar npc a cargar");
		}
		
		while (running) {
			if (chara) {
				if (keyp[SDLK_RIGHT]) chara.lrpx[0].selectObject++;
				if (keyp[SDLK_LEFT]) chara.lrpx[0].selectObject--;
				if (keyp[SDLK_DOWN]) chara.lrpx[0].selectObjectBlock++;
				if (keyp[SDLK_UP]) chara.lrpx[0].selectObjectBlock--;
			}
		
			updateInput();
			drawScene();
			SDL_GL_SwapBuffers();
		}
	} catch (Exception e) {
		printf("%s\n", toStringz(e.toString));
		system("pause");
	}

	return 0;
}
