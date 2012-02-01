private import dfl.all;

import std.string, std.stdio, std.thread, std.stream, std.file, std.path, std.c.stdio, std.c.stdlib, std.c.windows.windows;
import opengl;
import npc;

float angle_x = 0, angle_y = 0, angle_z = 0;
float position_x = 0, position_y = 0, position_z = 0;
float pos_x = 70, pos_y = 0, pos_z = 50, pos_w = 1.0f;
float dist = 250;
bool showAxis = false;
NPC chara;

class GLViewer : GLControl {
	bool update = false, updateOnce = false;
	bool running = true;
	
	bool shouldUpdate = false;
		
	this() {
		mea = new MouseEventArgs(cast(MouseButtons)0, 0, 0, 0, 0);
		super();
	}
	
	override protected void onHandleCreated(EventArgs ea) {
		super.onHandleCreated(ea);
		//chara = new NPC("models/TEA00.NPC");
		(new Worker()).start();
	}
	
	void drawAxis(float x = 0, float y = 0, float z = 0, float useDepth = false) {
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_LIGHTING);
		
		//glClear(GL_DEPTH_BUFFER_BIT);
		if (!useDepth) glDisable(GL_DEPTH_TEST);
		
		glEnable(GL_POINT_SMOOTH);
		glPointSize(8.0);
		glColor3f(0, 0, 0);
		
		glBegin(GL_POINTS);
			glVertex3f(0, 0, 0);
		glEnd();
		
		glColor3f(1, 0, 0); glBegin(GL_LINES); glVertex3f(0, 0, 0); glVertex3f(10,  0,  0); glEnd();
		glColor3f(0, 1, 0); glBegin(GL_LINES); glVertex3f(0, 0, 0); glVertex3f( 0, 10,  0); glEnd();
		glColor3f(0, 0, 1); glBegin(GL_LINES); glVertex3f(0, 0, 0); glVertex3f( 0,  0, 10); glEnd();
		glEnable(GL_DEPTH_TEST);
		
		glColor3f(1, 1, 1);
	}
	
	void initScene() {
		glViewport(0, 0, width, height);

		glShadeModel(GL_SMOOTH);
		
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);	
		glClearDepth(1.0f);
		//glClear(GL_COLOR_BUFFER_BIT);
		
		glEnable(GL_DEPTH_TEST);
		glDepthFunc(GL_LESS);

		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

		glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
		glEnable(GL_LINE_SMOOTH);
		glShadeModel(GL_SMOOTH);
		glDisable(GL_LIGHTING);

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		//gluPerspective(45.0f, cast(GLfloat)width / cast(GLfloat)height, 20.0f, 1200.0f);
		gluPerspective(45.0f, cast(GLfloat)width / cast(GLfloat)height, 1.0f, 1200.0f);

		glMatrixMode(GL_MODELVIEW);
	}
	
	void drawScene() {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glLoadIdentity();
		
		glTranslatef(0, 0, -dist);

		glRotatef(angle_x, 1, 0, 0);
		glRotatef(angle_y, 0, 1, 0);
		glRotatef(angle_z, 0, 0, 1);

		glTranslatef(position_x, position_y, position_z);

		if (chara) chara.draw();

		glTranslatef(-position_x, -position_y, -position_z);
		
		if (showAxis) drawAxis();
	}	

    override void onPaint(PaintEventArgs pea) {
		initScene();
		drawScene();
		
        super.onPaint(pea);
    }
	
	MouseEventArgs mea;

	bool dragl, dragr;
	float s_position_x, s_position_y, s_position_z;
	float s_angle_x, s_angle_y;
	int sx, sy;
	
	override void onMouseMove(MouseEventArgs mea) {
		updateOnce = true;
		
		if (dragl) {
			angle_y = s_angle_y + ((mea.x - sx) * dist) / 250;
			angle_x = s_angle_x + ((mea.y - sy) * dist) / 250;
		}
		if (dragr) {
			position_x = s_position_x + ((mea.x - sx) * dist) / 600;
			position_y = s_position_y - ((mea.y - sy) * dist) / 600;
		}

		super.onMouseMove(mea);
		this.mea = mea;
	}

	override void onMouseDown(MouseEventArgs mea) {
		updateOnce = true;
		showAxis = true;

		if ((mea.button & MouseButtons.LEFT) != 0) {
			dragl = true;
			s_angle_x = angle_x;
			s_angle_y = angle_y;
			sx = mea.x;
			sy = mea.y;
		}
		
		if ((mea.button & MouseButtons.RIGHT) != 0) {
			dragr = true;
			s_position_x = position_x;
			s_position_y = position_y;
			sx = mea.x;
			sy = mea.y;
		}		

		super.onMouseDown(mea);
		this.mea = mea;
	}

	override void onMouseUp(MouseEventArgs mea) {
		updateOnce = true;
		showAxis = false;
		
		if ((mea.button & MouseButtons.LEFT  ) != 0) dragl = false;
		if ((mea.button & MouseButtons.RIGHT ) != 0) dragr = false;
		
		super.onMouseUp(mea);
		this.mea = mea;
	}
	
	class Worker : Thread {
		override int run() {
			long bcounter, counter, frequency, delay;
			QueryPerformanceFrequency(&frequency);
			
			delay = frequency / 60;
		
			try {
				while (running) {
					std.c.windows.windows.QueryPerformanceCounter(&bcounter);
					
					if (update || updateOnce) {
						updateOnce = false;
						//try { makeCurrent(); } catch { }
						refresh();
						//try { wglMakeCurrent(null, null); } catch { }
					}

					while (true) {
						std.c.windows.windows.QueryPerformanceCounter(&counter);
						if (counter - bcounter >= delay) break;
						Sleep(1);
					}
					
					//doFrame();
					//refresh();
				}
			} catch (Exception e) {
				writefln("Worker.error: %s", e.toString);
			}
			
			return 0;
		}
	}	
}

class MainForm : Form, IMessageFilter {
	GLViewer glviewer;
	
	this() {
		icon = Application.resources.getIcon(101);
		
		//writefln("stage6");
		Application.addMessageFilter(this);
		
		MenuItem mitem;
        auto menu = new MainMenu();
        this.menu = menu;		
		
        mitem = new MenuItem("&Abrir");
		mitem.click ~= &open;
        menu.menuItems.add(mitem);

        mitem = new MenuItem("&Sobre...");
		mitem.click ~= &about;
        menu.menuItems.add(mitem);
		
		/*
        auto currentMenu = new MenuItem("&Archivo");
        menu.menuItems.add(currentMenu);
		
        auto currentItem = new MenuItem("&Abrir");
		currentItem.click ~= &open;
        currentMenu.menuItems.add(currentItem);
		*/
		
		text = "Tales of the Abyss - Visor de Modelos - 0.1beta";
		setClientSizeCore(640, 480);
		startPosition = FormStartPosition.CENTER_SCREEN;
		
		//writefln("stage7");
		with (glviewer = new GLViewer) {
			dock = DockStyle.FILL;
			parent = this;
			visible = true;			
		}
		
		//writefln("stage8");
	}
	
	void open(MenuItem c, EventArgs ea) {
		OpenFileDialog fd = new OpenFileDialog;
		
		fd.title = "Abrir modelos";
		fd.filter = "Archivos de NPC (*.NPC)|*.npc|Todos los archivos (*.*)|*.*";
		//fd.fileName = "EBOOT.PBP";
		if (fd.showDialog(this) == DialogResult.OK) {
			try {
				chara = new NPC(fd.fileName);
			} catch (Exception e) {
				writefln("Exception: %s", e.toString);
			}
		}
	}
	
	void about(MenuItem c, EventArgs ea) {
		msgBox(this, "soywiz 2008\nTales Translations", "Sobre");
	}
	
	protected override void onPaint(PaintEventArgs ea) {
	}
	
	int signExtend(int v, int pos) {
		int z = (1 << pos); int mask = z - 1;
		if (v & z) return -(~v & mask) - 1;
		return v;
	}
	
	override bool preFilterMessage(inout Message m) {
		switch (m.msg) {
			case 522:
				glviewer.updateOnce = true;
				int v = signExtend(m.wParam >> 20, 11);
				//writefln("%d", v);
				if (v < 0) {
					dist += dist / 10;
				} else {
					dist -= dist / 10;
				}
				return true;
			break;
			default:
			break;
		}
		
		return false;
	}	
}


int main() {
	int result = 0;
	
	//writefln("stage1");
	try {
		//writefln("stage2");
		glInitSystem();
		//writefln("stage3");
		gluInitSystem();
		//writefln("stage4");
		
		Application.enableVisualStyles();
		//writefln("stage5");
		Application.run(new MainForm);
	}
	catch(Object o) {
		msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
		result = 1;
	}
	
	return result;
}

