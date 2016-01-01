package flash.utils {
	public class md5 {
		/* private vars b64pad, chrsz */
		public static var b64pad:String   = '=';
		public static var chrsz:Number    = 8;
		private static var hex_tab:String = '0123456789ABCDEF';
		private static var tab:String     = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
		
		public static function hash(s:String):String { return hex_md5(s); }
		
		/// These are the functions you'll usually want to call
		/// They take string arguments and return either hex or base-64 encoded strings
		public static function hex_md5( s:String ):String {
			return binl2hex(core_md5(str2binl(s), s.length*chrsz));
		}
		
		public static function b64_md5( s:String ):String {
			return binl2b64(core_md5(str2binl(s), s.length*chrsz));
		}
		
		public static function str_md5( s:String ):String {
			return binl2str(core_md5(str2binl(s), s.length*chrsz));
		}
		
		public static function hex_hmac_md5( key:String, data:String ):String {
			return binl2hex(core_hmac_md5(key, data));
		}
		
		public static function b64_hmac_md5( key:String, data:String ):String {
			return binl2b64(core_hmac_md5(key, data));
		}
		
		public static function str_hmac_md5( key:String, data:String ):String {
			return binl2str(core_hmac_md5(key, data));
		}
		
		/// These functions implement the four basic operations the algorithm uses.
		private static function md5_cmn( q:Number, a:Number, b:Number, x:Number, s:Number, t:Number ):Number {
			return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b);
		}
		
		private static function md5_ff( a:Number, b:Number, c:Number, d:Number, x:Number, s:Number, t:Number ):Number {
			return md5_cmn((b & c) | ((~b) & d), a, b, x, s, t);
		}
		
		private static function md5_gg( a:Number, b:Number, c:Number, d:Number, x:Number, s:Number, t:Number ):Number {
			return md5_cmn((b & d) | (c & (~d)), a, b, x, s, t);
		}
		
		private static function md5_hh( a:Number, b:Number, c:Number, d:Number, x:Number, s:Number, t:Number ):Number {
			return md5_cmn(b ^ c ^ d, a, b, x, s, t);
		}
		
		private static function md5_ii( a:Number, b:Number, c:Number, d:Number, x:Number, s:Number, t:Number ):Number {
			return md5_cmn(c ^ (b | (~d)), a, b, x, s, t);
		}
		
		/// Calculate the MD5 of an array of little-endian words, and a bit length
		private static function core_md5( x:Array, len:Number ):Array {
			x[len >> 5] |= 0x80 << ((len)%32);
			x[(((len+64) >>> 9) << 4)+14] = len;
			var a:Number = 1732584193;
			var b:Number = -271733879;
			var c:Number = -1732584194;
			var d:Number = 271733878;
			for( var i:Number = 0; i < x.length; i += 16 ) {
				var olda:Number = a;
				var oldb:Number = b;
				var oldc:Number = c;
				var oldd:Number = d;
				a = md5_ff(a, b, c, d, x[i+0], 7, -680876936);
				d = md5_ff(d, a, b, c, x[i+1], 12, -389564586);
				c = md5_ff(c, d, a, b, x[i+2], 17, 606105819);
				b = md5_ff(b, c, d, a, x[i+3], 22, -1044525330);
				a = md5_ff(a, b, c, d, x[i+4], 7, -176418897);
				d = md5_ff(d, a, b, c, x[i+5], 12, 1200080426);
				c = md5_ff(c, d, a, b, x[i+6], 17, -1473231341);
				b = md5_ff(b, c, d, a, x[i+7], 22, -45705983);
				a = md5_ff(a, b, c, d, x[i+8], 7, 1770035416);
				d = md5_ff(d, a, b, c, x[i+9], 12, -1958414417);
				c = md5_ff(c, d, a, b, x[i+10], 17, -42063);
				b = md5_ff(b, c, d, a, x[i+11], 22, -1990404162);
				a = md5_ff(a, b, c, d, x[i+12], 7, 1804603682);
				d = md5_ff(d, a, b, c, x[i+13], 12, -40341101);
				c = md5_ff(c, d, a, b, x[i+14], 17, -1502002290);
				b = md5_ff(b, c, d, a, x[i+15], 22, 1236535329);
				a = md5_gg(a, b, c, d, x[i+1], 5, -165796510);
				d = md5_gg(d, a, b, c, x[i+6], 9, -1069501632);
				c = md5_gg(c, d, a, b, x[i+11], 14, 643717713);
				b = md5_gg(b, c, d, a, x[i+0], 20, -373897302);
				a = md5_gg(a, b, c, d, x[i+5], 5, -701558691);
				d = md5_gg(d, a, b, c, x[i+10], 9, 38016083);
				c = md5_gg(c, d, a, b, x[i+15], 14, -660478335);
				b = md5_gg(b, c, d, a, x[i+4], 20, -405537848);
				a = md5_gg(a, b, c, d, x[i+9], 5, 568446438);
				d = md5_gg(d, a, b, c, x[i+14], 9, -1019803690);
				c = md5_gg(c, d, a, b, x[i+3], 14, -187363961);
				b = md5_gg(b, c, d, a, x[i+8], 20, 1163531501);
				a = md5_gg(a, b, c, d, x[i+13], 5, -1444681467);
				d = md5_gg(d, a, b, c, x[i+2], 9, -51403784);
				c = md5_gg(c, d, a, b, x[i+7], 14, 1735328473);
				b = md5_gg(b, c, d, a, x[i+12], 20, -1926607734);
				a = md5_hh(a, b, c, d, x[i+5], 4, -378558);
				d = md5_hh(d, a, b, c, x[i+8], 11, -2022574463);
				c = md5_hh(c, d, a, b, x[i+11], 16, 1839030562);
				b = md5_hh(b, c, d, a, x[i+14], 23, -35309556);
				a = md5_hh(a, b, c, d, x[i+1], 4, -1530992060);
				d = md5_hh(d, a, b, c, x[i+4], 11, 1272893353);
				c = md5_hh(c, d, a, b, x[i+7], 16, -155497632);
				b = md5_hh(b, c, d, a, x[i+10], 23, -1094730640);
				a = md5_hh(a, b, c, d, x[i+13], 4, 681279174);
				d = md5_hh(d, a, b, c, x[i+0], 11, -358537222);
				c = md5_hh(c, d, a, b, x[i+3], 16, -722521979);
				b = md5_hh(b, c, d, a, x[i+6], 23, 76029189);
				a = md5_hh(a, b, c, d, x[i+9], 4, -640364487);
				d = md5_hh(d, a, b, c, x[i+12], 11, -421815835);
				c = md5_hh(c, d, a, b, x[i+15], 16, 530742520);
				b = md5_hh(b, c, d, a, x[i+2], 23, -995338651);
				a = md5_ii(a, b, c, d, x[i+0], 6, -198630844);
				d = md5_ii(d, a, b, c, x[i+7], 10, 1126891415);
				c = md5_ii(c, d, a, b, x[i+14], 15, -1416354905);
				b = md5_ii(b, c, d, a, x[i+5], 21, -57434055);
				a = md5_ii(a, b, c, d, x[i+12], 6, 1700485571);
				d = md5_ii(d, a, b, c, x[i+3], 10, -1894986606);
				c = md5_ii(c, d, a, b, x[i+10], 15, -1051523);
				b = md5_ii(b, c, d, a, x[i+1], 21, -2054922799);
				a = md5_ii(a, b, c, d, x[i+8], 6, 1873313359);
				d = md5_ii(d, a, b, c, x[i+15], 10, -30611744);
				c = md5_ii(c, d, a, b, x[i+6], 15, -1560198380);
				b = md5_ii(b, c, d, a, x[i+13], 21, 1309151649);
				a = md5_ii(a, b, c, d, x[i+4], 6, -145523070);
				d = md5_ii(d, a, b, c, x[i+11], 10, -1120210379);
				c = md5_ii(c, d, a, b, x[i+2], 15, 718787259);
				b = md5_ii(b, c, d, a, x[i+9], 21, -343485551);
				a = safe_add(a, olda);
				b = safe_add(b, oldb);
				c = safe_add(c, oldc);
				d = safe_add(d, oldd);
			}
			return [a, b, c, d];
		}
		
		/// Calculate the HMAC-MD5, of a key and some data
		private static function core_hmac_md5( key:String, data:String ):Array {
			var bkey:Array = new Array( str2binl( key ) );
			if( bkey.length > 16 ) {
				bkey = core_md5(bkey, key.length*chrsz);
			}
			var ipad:Array = new Array(16)
			var opad:Array = new Array(16);
			for( var i:Number = 0; i < 16; i++ ) {
				ipad[i] = bkey[i] ^ 0x36363636;
				opad[i] = bkey[i] ^ 0x5C5C5C5C;
			}
			var hash:Array = new Array( core_md5( ipad.concat( str2binl( data  )), 512 + data.length*chrsz ) );
			return core_md5(opad.concat(hash), 512+128);
		}
		
		/// Add integers, wrapping at 2^32. This uses 16-bit operations internally
		/// to work around bugs in some JS interpreters.
		private static function safe_add( x:Number, y:Number ):Number {
			var lsw:Number = new Number( (x & 0xFFFF) + (y & 0xFFFF) );
			var msw:Number = new Number( (x >> 16) + (y >> 16) + (lsw >> 16) );
			return (msw << 16) | (lsw & 0xFFFF);
		}
			
		/// Bitwise rotate a 32-bit number to the left.
		private static function bit_rol( num:Number, cnt:Number ):Number {
			return (num << cnt) | (num >>> (32-cnt));
		}
		
		/// Convert a string to an array of little-endian words
		/// If chrsz is ASCII, characters >255 have their hi-byte silently ignored.
		private static function str2binl( str:String ):Array {
			var bin:Array = new Array();
			var mask:Number = ( 1 << chrsz ) - 1;
			for( var i:Number = 0; i < str.length * chrsz; i += chrsz ) {
				bin[i >> 5] |= (str.charCodeAt(i/chrsz) & mask) << (i%32);
			}
			return bin;
		}
		
		/// Convert an array of little-endian words to a string
		private static function binl2str( bin:Array ):String {
			var str:String = new String( "" );
			var mask:Number = ( 1 << chrsz )-1;
			for( var i:Number = 0; i < bin.length * 32; i += chrsz ) {
				str += String.fromCharCode( ( bin[i >> 5] >>> ( i % 32 ) ) & mask );
			}
			return str;
		}
		
		/// Convert an array of little-endian words to a hex string.
		private static function binl2hex( binarray:Array ):String {
			var str:String = '';
			for( var i:Number = 0; i < binarray.length * 4; i++ ) {
				str += hex_tab.charAt( ( binarray[i>>2] >> ( ( i%4 ) * 8 + 4 ) ) & 0xF ) + 
				hex_tab.charAt( ( binarray[i>>2] >> ( ( i%4 ) * 8  ) ) & 0xF );
			}
			return str;
		}
		
		/// Convert an array of little-endian words to a base-64 string
		private static function binl2b64( binarray:Array ):String {
			var str:String = '';
			for( var i:Number = 0; i < binarray.length * 4; i += 3 ) {
				var triplet:Number = (((binarray[i   >> 2] >> 8 * ( i   %4)) & 0xFF) << 16) 
				| (((binarray[i+1 >> 2] >> 8 * ((i+1)%4)) & 0xFF) << 8 ) 
				| ((binarray[i+2 >> 2] >> 8 * ((i+2)%4)) & 0xFF);
				for(var j:int = 0; j < 4; j++) {
					if( i * 8 + j * 6 > binarray.length * 32 ) {
						str += b64pad;
					}
					else {
						str += tab.charAt( ( triplet >> 6 * ( 3 - j ) ) & 0x3F );
					}
				}
			}
			return str;
		}
	}
}