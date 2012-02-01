module npc;

import std.string, std.stream, std.stdio, std.math, std.intrinsic, std.file, std.path;

import util, opengl;
import txd, rpx;

class NPC {
	RPX[] lrpx;
	
	void draw() {
		foreach (rpx; lrpx) rpx.draw();
	}
	
	void process(Stream s) {
		uint count, hstart, hend;
		
		if (s.readString(4) != "FPS3") {
			lrpx ~= new RPX(new SliceStream(s, 0));
			throw(new Exception("Invalid NPC file"));
		}
		
		s.read(count);
		s.read(hstart);
		s.read(hend);
		
		Stream ss = new SliceStream(s, hstart, hend);
		for (int n = 0; n < count; n++) {
			uint pos, len;
			ss.read(pos);
			ss.read(len);
			char[] name = std.string.toString(toStringz(ss.readString(4)));
			if (!name.length) continue;
			switch (name) {
				default: break;
				case "rpx":
					lrpx ~= new RPX(new SliceStream(s, pos, pos + len));
				break;
			}
		}
	}
	
	this(Stream s) {
		process(s);
	}
	
	this(char[] file) {
		auto s = new BufferedFile(file, FileMode.In);
		process(s);
	}
}

// http://www.gtamodding.com/index.php?title=List_of_RW_section_IDs