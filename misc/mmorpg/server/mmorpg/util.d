module mmorpg.util;

import std.stdio;
import std.socket, std.socketstream, std.stream;
import std.traits;

alias short  s16;
alias int    s32;
alias long   s64;

alias ushort u16;
alias uint   u32;
alias ulong  u64;

struct Point { int x, y; }

class TEntryList(T) {
	int  count = 0; bool[T] elist;
	void add(T e)    { elist[e] = true; if (count++ % 0x10 == 0xF) elist = elist.rehash; }
	void remove(T e) { if (has(e)) elist.remove(e); }
	bool has(T e)    { return (e in elist) != null; }
	void opAddAssign(T e) { elist[e] = true; if (count++ % 0x10 == 0xF) elist = elist.rehash; }
	void opSubAssign(T e) { if (has(e)) elist.remove(e); }	
	T[]  list()      { return elist.keys; }
	int  length()    { return elist.length; }
}

class TEntryListMap(T) : TEntryList {
}

class TEntryListNear(T) {
	TEntryList!(T) list;
	TEntryList!(T)[int][int] boxList;
	uint xBoxSize, yBoxSize;

	Point getBox(T e) {
		Point r = void;
		r.x = e.x / xBoxSize;
		r.y = e.y / yBoxSize;
		return r;
	}
}


template Event(T1, T2) {
	struct Event {
		alias void delegate(T1, T2) Handler;
		
		
		void addHandlerExact(Handler handler)
		in
		{
			assert(handler);
		}
		body
		{
			if(!_array.length)
			{
				_array = new Handler[2];
				_array[1] = handler;
				unsetHot();
			}
			else
			{
				if(!isHot())
				{
					_array ~= handler;
				}
				else // Hot.
				{
					_array = _array ~ (&handler)[0 .. 1]; // Force duplicate.
					unsetHot();
				}
			}
		}
		
		
		/// Add an event handler with parameter contravariance.
		void addHandler(TDG)(TDG handler)
		in
		{
			assert(handler);
		}
		body
		{
			mixin _validateHandler!(TDG);
			
			addHandlerExact(cast(Handler)handler);
		}
		
		
		/// Shortcut for addHandler().
		void opCatAssign(TDG)(TDG handler)
		{
			addHandler!(TDG)(handler);
		}
		
		
		/// Remove the specified event handler with the exact Handler type.
		void removeHandlerExact(Handler handler)
		{
			if(!_array.length)
				return;
			
			size_t iw;
			for(iw = 1; iw != _array.length; iw++)
			{
				if(handler == _array[iw])
				{
					if(iw == 1 && _array.length == 2)
					{
						_array = null;
						break;
					}
					
					if(iw == _array.length - 1)
					{
						_array[iw] = null;
						_array = _array[0 .. iw];
						break;
					}
					
					if(!isHot())
					{
						_array[iw] = _array[_array.length - 1];
						_array[_array.length - 1] = null;
						_array = _array[0 .. _array.length - 1];
					}
					else // Hot.
					{
						_array = _array[0 .. iw] ~ _array[iw + 1 .. _array.length]; // Force duplicate.
						unsetHot();
					}
					break;
				}
			}
		}
		
		
		/// Remove the specified event handler with parameter contravariance.
		void removeHandler(TDG)(TDG handler)
		{
			mixin _validateHandler!(TDG);
			
			removeHandlerExact(cast(Handler)handler);
		}
		
		
		/// Fire the event handlers.
		void opCall(T1 v1, T2 v2)
		{
			if(!_array.length)
				return;
			setHot();
			
			Handler[] local;
			local = _array[1 .. _array.length];
			foreach(Handler handler; local)
			{
				handler(v1, v2);
			}
			
			if(!_array.length)
				return;
			unsetHot();
		}
		
		
		///
		int opApply(int delegate(Handler) dg)
		{
			if(!_array.length)
				return 0;
			setHot();
			
			int result = 0;
			
			Handler[] local;
			local = _array[1 .. _array.length];
			foreach(Handler handler; local)
			{
				result = dg(handler);
				if(result)
					break;
			}
			
			if(_array.length)
				unsetHot();
			
			return result;
		}
		
		
		///
		bool hasHandlers() // getter
		{
			return _array.length > 1;
		}
		
		
		private:
		Handler[] _array; // Not what it seems.
		
		
		void setHot()
		{
			assert(_array.length);
			_array[0] = cast(Handler)&setHot; // Non-null, GC friendly.
		}
		
		
		void unsetHot() {
			assert(_array.length);
			_array[0] = null;
		}
		
		
		Handler isHot() {
			assert(_array.length);
			return _array[0];
		}
		
		
		// Thanks to Tomasz "h3r3tic" Stachowiak for his assistance.
		template _validateHandler(TDG)
		{
			static assert(is(TDG == delegate), "DFL: Event handler must be a delegate");
			
			alias ParameterTypeTuple!(TDG) TDGParams;
			static assert(TDGParams.length == 2, "DFL: Event handler needs exactly 2 parameters");
			
			static if(is(TDGParams[0] : Object))
			{
				static assert(is(T1: TDGParams[0]), "DFL: Event handler parameter 1 type mismatch");
			}
			else
			{
				static assert(is(T1 == TDGParams[0]), "DFL: Event handler parameter 1 type mismatch");
			}
			
			static if(is(TDGParams[1] : Object))
			{
				static assert(is(T2 : TDGParams[1]), "DFL: Event handler parameter 2 type mismatch");
			}
			else
			{
				static assert(is(T2 == TDGParams[1]), "DFL: Event handler parameter 2 type mismatch");
			}
		}
	}
}

class EventArgs {
	private static const EventArgs _e;
	static this() { _e = new EventArgs; }
	static EventArgs empty() { return _e; } 
}

class TextEventArgs {
	char[] s;
	this(char[] s) { this.s = s; }
}