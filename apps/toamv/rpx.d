module rpx;

import std.string, std.stream, std.stdio, std.math, std.intrinsic, std.file, std.path;

import util, opengl;
import txd;


class RPX {
	struct Vertex {
		V3D pos;
		V2D tex;
		uint color;
	}
	
	struct OBJ {
		V3D[]  vertex_pos;
		V2D[]  vertex_tex;
		V3D[]  vertex_normal;
		uint[] vertex_color;
		int[]  vertex_count;
		Texture tex;
	}
	
	OBJ* object;
	OBJ[] objects;
	TXD[] txds;
	Texture[char[]] texs;
	
	void exportOBJ(Stream s, Stream sm) {
		s.writefln("mtllib ./out.mtl");

		s.writefln("g");
		
		void exportTS(int offset, int count) {
			for (int n = 0; n < count - 2; n++) {
				s.writefln("s 1");
				s.writefln(
					"f %d/%d/%d %d/%d/%d %d/%d/%d",
					offset + n + 0, offset + n + 0, offset + n + 0,
					offset + n + 1, offset + n + 1, offset + n + 1,
					offset + n + 2, offset + n + 2, offset + n + 2,
				"");
			}
		}

		foreach (k, o; objects) foreach (v; o.vertex_pos) s.writefln("v\t%f %f %f", v.x, v.y, v.z);
		foreach (k, o; objects) foreach (v; o.vertex_tex) s.writefln("vt\t%f %f %f", v.x, v.y, 1.0f);
		foreach (k, o; objects) foreach (v; o.vertex_pos) s.writefln("vn\t%f %f %f", 0.0f, 0.0f, 0.0f);
		
		int pos = 1;
		
		foreach (k, o; objects) {
			s.writefln("g OBJ%d", k);
			s.writefln("usemtl MAT%d", k);
			sm.writefln("newmtl MAT%d", k);
			sm.writefln("Ka  1.0 1.0 1.0");
			sm.writefln("Kd  1.0 1.0 1.0");
			sm.writefln("Ks  0.9 0.9 0.9");
			sm.writefln("d  1.0");
			sm.writefln("Ns  0.0");
			sm.writefln("illum 2");
			sm.writefln("map_Kd ./out_%d.bmp", k);
			if (o.tex) o.tex.save(std.string.format("out_%d.bmp", k));
			
			foreach (count; o.vertex_count) {
				exportTS(pos, count);
				pos += count;
			}
		}
	}	
	
	Texture getTexture(char[] name) {
		if ((name in texs) !is null) return texs[name];
		
		foreach (txd; txds) {
			auto t = txd.get(name);
			if (t != null) {
				texs[name] = *t;
				return *t;
			}
		}
		
		//texs[name] = Texture.fromFile(name ~ ".tga"); return texs[name];
		
		throw(new Exception("Unknown texture '" ~ name ~ "'"));
	}
	
	bool drawSelection = false;
	int selectObject = 0;
	int selectObjectBlock = 0;
	
	void drawBase() {
		//glColor4f(1, 1, 1, 1);
		glEnable(GL_BLEND);
		
		//glPolygonMode (GL_BACK, GL_FILL);
		//glCullFace (GL_BACK);			
		
		foreach (k, object; objects) {
			bool objectSelected = false;
			//if (k == 2) glColor3f(1, 0, 0); else glColor3f(1, 1, 1);
			glColor3f(1, 1, 1);
			/*if (drawSelection) {
				if ((selectObject % objects.length) == k) {
					objectSelected = true;
					glColor3f(1.0, 0.6, 0.6);
				}
			}*/
			
			if (object.tex) {
				glEnable(GL_TEXTURE_2D);
				object.tex.bind();
			} else {
				glDisable(GL_TEXTURE_2D);
			}
			V3D*  pos = object.vertex_pos.ptr;
			V2D*  tex = object.vertex_tex.ptr;
			uint* col = object.vertex_color.ptr;

			glPushClientAttrib(GL_CLIENT_VERTEX_ARRAY_BIT);
			
			glEnableClientState(GL_VERTEX_ARRAY);
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			//glEnableClientState(GL_COLOR_ARRAY);
			
				//int count = object.vertex_pos.length;
				foreach (k2, count; object.vertex_count) {
					
					/*if (drawSelection && objectSelected) {
						glPushAttrib(GL_CURRENT_BIT);
						if ((selectObjectBlock % object.vertex_count.length) == k2) {
							glDisable(GL_TEXTURE_2D);
							glColor3f(0, 0, 1);
						}
					}*/
					glVertexPointer(3, GL_FLOAT, 0, pos);
					glTexCoordPointer(2, GL_FLOAT, 0, tex);
					//glColorPointer(4, GL_UNSIGNED_BYTE, 0, col);
					
					glDrawArrays(GL_TRIANGLE_STRIP, 0, count);
					pos += count;
					tex += count;

					/*if (drawSelection && objectSelected) {
						glPopAttrib();
						glEnable(GL_TEXTURE_2D);
					}*/
				}
			
			glPopClientAttrib();
		}
	}
	
	uint callList;
	
	void draw() {
		drawBase(); return;
		
		if (callList) {
			glCallList(callList);
			return;
		}
		callList = glGenLists(1);
		glNewList(callList, GL_COMPILE_AND_EXECUTE);
			drawBase();
		glEndList();
	}
	
	void processTXD(StreamBlock s) {
		txds ~= new TXD(s);
	}

	void processModelProperties(StreamBlock s) { // 0x0E - FrameList
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						sb.unprocess();
					break;
					case 0x03: // 0x03 - Extension
						sb.unprocess();
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}
	
	void processModelObjectsObjectFragmentsFragmentMaterial(StreamBlock s) { // 0x06 - Texture
		//writefln("processModelObjectsObjectFragmentsFragmentMaterial");
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						sb.unprocess();
					break;
					case 0x02: // 0x02 - String
						char[] name = std.string.toString(toStringz(sb.s.readString(sb.s.size)));
						if (name.length) {
							//sb.pad(); writefln("'%s'", name);
							//writefln("  %s", name);
							object.tex = getTexture(name);
						}
					break;
					case 0x03: // 0x03 - Extension
						sb.unprocess();
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}
	
	void processModelObjectsObjectFragmentsFragment(StreamBlock s) { // 0x07 - Material
		objects.length = objects.length + 1;
		object = &objects[objects.length - 1];
		
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				//writefln(sb.type);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						//sb.writeTo("temp11");
						sb.unprocess();
					break;
					case 0x06: // 0x06 - Texture
						processModelObjectsObjectFragmentsFragmentMaterial(sb);
					break;
					case 0x03: // 0x03 - Extension
						sb.unprocess();
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}		

	void processModelObjectsObjectFragments(StreamBlock s) { // 0x08 - Material List
		static count = 0;
		//s.writeTo(std.string.format("frag%03d.temp", count++));
		//uint a, b; s.s.read(a); s.s.read(b);
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						sb.unprocess();
					break;
					case 0x07: // 0x07 - Material
						processModelObjectsObjectFragmentsFragment(sb);
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}
	
	int object_cur = 0;
	
	void processGeom(Stream s) {
		int cur = 0;
		void processBlock(Stream s, int offsetStart = 0) {
			OBJ* object = &objects[cur];
			
			writefln("Process Block (%d)", cur);
			
			while (!s.eof) {
				uint unk, sync, type;
				uint blockStart = s.position;
				s.read(unk);
				s.read(sync);
				s.read(type);
				
				if (sync != 0x01000105) {
					throw(new Exception(std.string.format("Invalid GeomSYNC 0x%08X at 0x%08X", sync, blockStart + offsetStart)));
				}

				//writefln("type: %08X : %08X", type, s.position);
				uint vertexCount = (type >> 16) & 0xFF;
				
				switch ((type >> 24) & 0xFF) {
					default: throw(new Exception(std.string.format("Invalid GeomPacket 0x%08X", type >> 24)));
					case 0x6C: // Info
						object.vertex_count ~= vertexCount;
						for (int n = 0; n < 8; n++) {
							uint v;
							s.read(v);
							//if (n == 0) writefln("INFO: %08X", v);
						}
						//writefln();
						//{ ubyte[] temp; temp.length = 0x20;
						//s.read(temp); }
					break;
					case 0x68: // Vertex
						for (int n = 0; n < vertexCount; n++) {
							float x, y, z;
							s.read(x); s.read(y); s.read(z);
							object.vertex_pos ~= V3D(x, y, z);
						}
					break;
					case 0x64: // Coords
						for (int n = 0; n < vertexCount; n++) {
							float u, v;
							s.read(u); s.read(v);
							object.vertex_tex ~= V2D(u, v);
						}
					break;
					case 0x6E:  // VertexColors
						for (int n = 0; n < vertexCount; n++) {
							uint c;
							s.read(c);
							object.vertex_color ~= c;
						}
					break;
					case 0x6A: // Unknown?
						{ ubyte[] temp; temp.length = 0x90;
						s.read(temp); }
						while (!s.eof) {
							uint msync;
							try {
								s.read(msync);
							} catch {
								break;
							}
							if (msync == 0x01000105) {
								s.position = s.position - 0x10;
								break;
							}
						}
					break;
				}
				
				//while ((s.position % 0x10) != 0) s.position = s.position + 4;
				//if (s.position % 0x10)
				s.position = s.position + (0x10 - (s.position % 0x10));
			}	
		}
	
		uint count;
		s.read(count);
		writefln("processGeom(%d)", count);
		for (cur = 0; cur < count; cur++, object_cur++) {
			ulong len; uint zsync;
			//writefln("  POS: 0x%08X", s.position);
			try {
				s.read(len);
				s.read(zsync);

				processBlock(new SliceStream(s, s.position, s.position + len - 4), s.position);
			} catch (Exception e) {
				cur++;
				writefln("Exception: %s", e.toString);
				//break;
			}
			s.position = s.position + len - 4;
		}
	}
	
	void processModelObjectsObjectGeometry2(StreamBlock s) { // 0x0510 - ?
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01:
						//sb.writeTo("_rpx.geom");
						processGeom(sb.s);
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}
	
	void processModelObjectsObjectGeometry(StreamBlock s) { // 0x0F-0x03 - Extension
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x050E: // ?
						sb.unprocess();
					break;
					case 0x0510: // ?
						processModelObjectsObjectGeometry2(sb);
					break;
					case 0x0116: // ?
						sb.unprocess();
					break;
					case 0x011F: // ?
						sb.unprocess();
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}
	
	void processModelObjectsObject(StreamBlock s) { // 0x0F - Geometry
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						sb.unprocess();
					break;
					case 0x08: // 0x08 - Material List
						processModelObjectsObjectFragments(sb);
					break;
					case 0x03: // 0x03 - Extension
						processModelObjectsObjectGeometry(sb);
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}	
	
	void processModelObjects(StreamBlock s) { // 0x1A - Geometry List
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						uint count;
						sb.s.read(count);
						sb.unprocess();
					break;
					case 0x0F: // 0x0F - Geometry 
						processModelObjectsObject(sb);
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}	
	}	

	void processModel(StreamBlock s) { // 0x10 - Clump
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02000F);
				switch (sb.type) {
					default: sb.unknown(); break;
					case 0x01: // 0x01 - Struct
						sb.unprocess();
					break;
					case 0x0E: // 0x0E - Frame List
						sb.unprocess();
						processModelProperties(sb);
					break;
					case 0x1A: // 0x1A - Geometry List
						processModelObjects(sb);
					break;
					case 0x14: // 0x14 - Atomic
						sb.unprocess();
					break;
					case 0x03: // 0x03 - Extension
						sb.unprocess();
					break;
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}
	}

	void processBase(StreamBlock s) { // ---
		try {
			while (!s.eof) {
				auto sb = readStreamBlock(s, 0x1C02002D);
				switch (sb.type) {
					default:   sb.unknown();     break;
					case 0x16: processTXD(sb);   break; // 0x16 - Texture Dictionary
					case 0x10: processModel(sb); break; // 0x10 - Clump
					case 0x1B: sb.unprocess();   break; // 0x1B - Anim Animation
					case 0x29: sb.unprocess();   break; // 0x29 - Chunk Group Start
					case 0x2A: sb.unprocess();   break; // 0x2A - Chunk Group End
				}
			}
		} catch (StreamBlockEND e) {
			//writefln("eos");
		}
	}
	
	int texs_length() {
		int l;
		foreach (txd; txds) l += txd.length;
		return l;
	}
	
	void process(Stream s) {
		StreamBlock sb = new StreamBlock();
		sb.type = 0;
		sb.len = s.size;
		sb.s = s;
		sb.sbase = s;
		sb.spos = s.position;
		processBase(sb);
		
		writefln("TXDS: %d (%d)", txds.length, texs_length);
		writefln("OJBS: %d", objects.length);
	}
	
	this(Stream s) {
		process(s);
	}	
}