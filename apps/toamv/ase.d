module ase;

import std.stream, std.stdio, std.string, std.math, std.regexp;
import util;
import opengl;

struct ASE {
	V3D[] vertexList;
	FACE[] faceList;
	
	void draw(bool faces = true, bool wire = false, bool border = true) {
		glEnable(GL_LIGHTING);
		glEnable(GL_LIGHT0);
		
		glLightModelfv(GL_LIGHT_MODEL_AMBIENT, [ 1.0f, 0.0f, 0.0f, 0.5f ].ptr);
		glShadeModel(GL_SMOOTH);
		
		glEnable(GL_DEPTH_TEST);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_CULL_FACE);
		glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
		//glDepthFunc (GL_LEQUAL);
		glDepthFunc (GL_LESS);
		glEnable(GL_BLEND);
		
		//glDisable(GL_DEPTH_TEST); glDisable(GL_CULL_FACE);
		
		if (faces) {
		//if (false) {
			
			/*
			glLightfv(GL_LIGHT0, GL_POSITION, [0.0f, 0.0f, -200.0f].ptr);
			//glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, [0.0f, 0.0f, -10.0f].ptr);
			
			glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, [1.0f, 0.0f, 0.0f, 1.0f].ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, [0.0f, 0.0f, 1.0f, 1.0f].ptr);			
			*/
			
			glEnable ( GL_COLOR_MATERIAL ) ;
		
			glPolygonMode(GL_BACK, GL_FILL);
			glCullFace(GL_BACK);
			glColor4f(1, 1, 1, 1.0);
			glBegin(GL_TRIANGLES);
			foreach (face; faceList) {
				glNormal3fv(cast(float *)&face.vn[0]);
				glVertex3fv(cast(float *)&vertexList[face.a]);

				glNormal3fv(cast(float *)&face.vn[1]);
				glVertex3fv(cast(float *)&vertexList[face.b]);

				glNormal3fv(cast(float *)&face.vn[2]);
				glVertex3fv(cast(float *)&vertexList[face.c]);
			}
			glEnd();
		}

		if (border) {
		//if (false) {
			glPolygonMode (GL_BACK, GL_LINE);		// Draw Backfacing Polygons As Wireframes
			glLineWidth (3);			// Set The Line Width
			glCullFace (GL_FRONT);				// Don't Draw Any Front-Facing Polygons
			//glColor3fv (&outlineColor[0]);			// Set The Outline Color
		
			glColor4f(0, 0, 0, 0.8);
			glBegin(GL_TRIANGLES);
			foreach (face; faceList) {
				glVertex3fv(cast(float *)&vertexList[face.a]);
				glVertex3fv(cast(float *)&vertexList[face.b]);
				glVertex3fv(cast(float *)&vertexList[face.c]);
			}
			glEnd();
			
			//glDepthFunc (GL_LESS);
		}
		
		if (wire) {
			glDisable(GL_DEPTH_TEST);
			glColor3f(0, 0, 1);
			glBegin(GL_LINES);
			foreach (face; faceList) {
				if (face.ab) {
					glVertex3fv(cast(float *)&vertexList[face.a]);
					glVertex3fv(cast(float *)&vertexList[face.b]);
				}
				if (face.bc) {
					glVertex3fv(cast(float *)&vertexList[face.b]);
					glVertex3fv(cast(float *)&vertexList[face.c]);
				}
				if (face.ca) {
					glVertex3fv(cast(float *)&vertexList[face.a]);
					glVertex3fv(cast(float *)&vertexList[face.c]);
				}
			}
			glEnd();
			glEnable(GL_DEPTH_TEST);
		}
	}

	V3D  measureCached;
	bool measureCachedHAS;
	
	V3D measure() {
		if (measureCachedHAS) return measureCached;
		
		float mx, my, mz;
		float Mx, My, Mz;
		
		void f_min(inout float l, float v) { if (isnan(l) || (v < l)) l = v; }
		void f_max(inout float l, float v) { if (isnan(l) || (v > l)) l = v; }
		void f_min_max(inout float l, inout float L, float v) { f_min(l, v); f_max(L, v); }
		
		foreach (v; vertexList) {
			f_min_max(mx, Mx, v.x);
			f_min_max(my, My, v.y);
			f_min_max(mz, Mz, v.z);
		}
		
		measureCachedHAS = true;
		return measureCached = V3D(Mx - mx, My - my, Mz - mz);
	}
}

ASE casa;

ASE loadASE(char[] file) {
	ASE ase;
	auto s = new File(file);
	int face, facep;
	
	while (!s.eof) {
		auto l = strip(s.readLine());
		if (!l.length) continue;
		if (l[0] != '*') continue;
		
		auto pp = RegExp(r"\*(\w+)\s(.*)").match(l);
		char[][] pr;
		if (pp.length == 3) {
			pr = RegExp(r"[-\d\.]+", "g").match(pp[2]);
		}
		
		//writefln(pr);
		
		//writefln(pp[1]);
		switch (pp[1]) {
			default: break;
			case "MESH_NUMVERTEX": ase.vertexList.length = atoi(pr[0]); break;
			case "MESH_NUMFACES" : ase.faceList.length = atoi(pr[0]); break;
			case "MESH_VERTEX":
				int id = atoi(pr[0]);
				float x = atof(pr[1]), y = atof(pr[2]), z = atof(pr[3]);
				ase.vertexList[id] = V3D(x, y, z);
			break;
			case "MESH_FACE":
				int id = atoi(pr[0]);
				int a = atoi(pr[1]), b = atoi(pr[2]), c = atoi(pr[3]);
				int ab = atoi(pr[4]), bc = atoi(pr[5]), ca = atoi(pr[6]);
				ase.faceList[id] = FACE(a, b, c, ab, bc, ca);
			break;
			case "MESH_FACENORMAL":
				float x = atof(pr[1]), y = atof(pr[2]), z = atof(pr[3]);
				face = atoi(pr[0]); facep = 0;
				ase.faceList[face].fn = V3D(x, y, z);
			break;
			case "MESH_VERTEXNORMAL":
				float x = atof(pr[1]), y = atof(pr[2]), z = atof(pr[3]);
				ase.faceList[face].vn[facep++] = V3D(x, y, z);
			break;
		}
	}
	
	writefln(ase.vertexList.length);
	
	return ase;
}
