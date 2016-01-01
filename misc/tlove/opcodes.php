<?php
	function fread1($f) { @list(, $r) = unpack('C', fread($f, 1)); return $r; }
	function fread2($f) { @list(, $r) = unpack('v', fread($f, 2)); return $r; }
	function fread4($f) { @list(, $r) = unpack('V', fread($f, 4)); return $r; }
	function fread1n($f) { @list(, $r) = unpack('C', fread($f, 1)); return $r; }
	function fread2n($f) { @list(, $r) = unpack('n', fread($f, 2)); return $r; }
	function fread4n($f) { @list(, $r) = unpack('N', fread($f, 4)); return $r; }
	function freadsz($f, $l) { return rtrim(fread($f, $l), "\0"); }
	function error($s = 'error') { throw(new Exception($s)); }
	
	function safestring($s) {
		$r = '';
		for ($n = 0, $l = strlen($s); $n < $l; $n++) {
			$r .= ctype_print($s[$n]) ? $s[$n]: '.';
		}
		return $r;
	}

	function parse_data($scr_pos, $op, $data) {
		static $opcodes = array(
			0x00 => array('EOF',         ''     ),
			
			0x19 => array('NAME_L',      '1s1'     ),
			
			0x28 => array('JUMP',        'J'    ),
			0x2B => array('CALL',        'J'    ),
			
			0x33 => array('IMG_LOAD',    's1'   ), // Load image
			0x36 => array('IMG_PUT',     '1112222122222'), // PUT IMAGE ?, ?, ?, slice_x, slice_y, slice_w, slice_h, ?, put_x, put_y, ?, ?, ?
			0x38 => array('ANI_LOAD',    's1'   ), // Animation
			0x3A => array('FILL_RECT',   '112222' ),
			0x3C => array('PALETTE',     '11111' ),
			
			0x41 => array('JUMP_IF_REL', '221'  ),
			
			0x44 => array('JUMP_IF',     '112J' ), // OPTION ?, ? // FF 01 (maybe flag?), item_n, jump_n
			
			0x49 => array('?49',         '111' ), //
			
			0x4C => array('?49',         '12' ), //
			
			0x52 => array('SCRIPT_LOAD', 's1'), // SCRIPT LOAD OR CALL?
			0x53 => array('?53',         '21'   ),
			
			0x61 => array('MUSIC_PLAY',  's2'   ), // MUSIC: PLAY?
			0x63 => array('MUSIC_STOP',  ''     ), // MUSIC: STOP?
			
			0x70 => array('TEXT_DIALOG', '111s2'), // Put dialog
			0x71 => array('TEXT_PUT',    '221s2'), // Put text (y, x, ?color?, text, ??)

			0x89 => array('DELAY',       '2'),     // 
			0x8A => array('UPDATE',      ''),     // 
			
			0x91 => array('RETURN',      ''), //
			
			0x95 => array('FLAG_SET_RANGE', '1221'),
			
			0xA6 => array('WAIT_CLICK', 'JJ'),
			0xA7 => array('JUMP_MOUSE_IN', '2222J'),
			0xAD => array('JUMP_IF_MOUSE_START', 'JJJ1'),
			0xAE => array('JUMP_IF_MOUSE_IN', '2222J12'),
			
			//0x98 => array('?98', ''), // var related | 98: 09 : 800600800601001E04 | -3000 ens
		);
	/*
	</ id=0xAD, format="2221", description="" />
	function JUMP_IF_MOUSE_START(label_l, label_r, label_miss, count) {
	*/
		/*
	</ id=0xA7, format="22222", description="" />
	function JUMP_MOUSE_IN(x1, y1, x2, y2, label) {
		local mx = mouse.x, my = mouse.y;

		if (mouse.bl && (mx >= x1 && mx < x2 && my >= y1 && my < y2)) {
			jump_label(label);
		}
	}

		*/

		$len = strlen($data);
		
		//$f = fopen('php://memory', 'rb+'); fwrite($f, $data); rewind($f);
		$f = fopen('data://text/plain;base64,' . base64_encode($data), 'rb');
		$cop_a = &$opcodes[$op];
		if (!isset($cop_a)) {
			$ret = strtoupper(bin2hex($data)) . '(' . $data . ')';
			printf("  (%04X) %02X: %02X : %s\n", $scr_pos, $op, $len, safestring($ret));
			return $ret;
			//return strtoupper(bin2hex($data));
		}
		$params = array();
		list($name, $cop) = $cop_a;
		for ($n = 0, $l = strlen($cop); $n < $l; $n++) { $c = $cop[$n];
			switch ($c) {
				case '1': $params[] = fread1n($f); break;
				case '2': $params[] = fread2n($f); break;
				case 'J': $params[] = sprintf('LABEL_%04X', fread2n($f)); break;
				case 's':
					$s = '';
					while (!feof($f) && ($c = fgetc($f)) != "\0") $s .= $c;
					$s = strtr($s, array(
						"\xFF" => '<NAME>',
						"\x01" => '<01>',
						"\x02" => '<02>',
						"\x03" => '<03>',
						"\x04" => '<04>',
						"\x05" => '<05>',
						"\x06" => '<06>',
						"\x07" => '<07>',
						"\x08" => '<08>',
						"\n" => '\n',
						"\r" => '\r',
						"\t" => '\t',
						"\"" => '"',
					));
					$params[] = '"' . $s . '"';
				break;
				case 'F':
					while (!feof($f) && ($c = fread1n($f)) != 0xFF) $params[] = $c;
				break;
			}
		}
		printf("  (%04X) %-20s : %s\n", $scr_pos, $name, implode(', ', $params));
		return implode(', ', $params);
	}
	
	function processDAT($file) {	
		//$f = fopen('DATE.d/701.DAT', 'rb');
		//$f = fopen('DATE.d/TITLE.DAT', 'rb');
		//$f = fopen('DATE.d/ENDING.DAT', 'rb');
		//$f = fopen('tlove/DATE.d/MAIN.DAT', 'rb');
		$f = fopen($file, 'rb');
		$begin = fread2n($f);
		
		$ptr_count = ($begin - 10 - 2) / 2;
		$ptrs = array();
		for ($n = 0; $n < $ptr_count; $n++) {
			$ptrs[] = $cptr = fread2n($f);
			//printf("PTR(%02X) : %04X\n", $n, $cptr);
		}
		
		$ptrs_keys = array_flip($ptrs);
		
		fseek($f, $begin);
		
		while (!feof($f)) {
			$scr_pos = ftell($f) - $begin;
			
			$ptr_key = &$ptrs_keys[$scr_pos];
			if (isset($ptr_key)) {
				printf("\n@LABEL_%04X (%04X)\n", $ptr_key, $scr_pos);
			}
			$op   = fread1n($f);
			$len  = fread1n($f);
			if ($len & 0x80) {
				$len = fread1n($f) | (($len & 0x7F) << 8);
				//error('Check len size');
			}
			$data = ($len > 0) ? fread($f, $len) : '';
			parse_data($scr_pos, $op, $data);
			//printf("  (%04X) %02X: %02X : %s\n", $scr_pos, $op, $len, parse_data($scr_pos, $op, $data));
			//printf("  (%04X) %02X: %02X : %s\n", $scr_pos, $op, $len, parse_data($scr_pos, $op, $data));
		}
	}
	
	@mkdir('txt');
	foreach (scandir($path = 'tlove/DATE.d') as $file) {
		if ($file[0] == '.') continue;
		$rfile = "{$path}/{$file}";
		echo "$file...";
		ob_start();
		processDAT($rfile);
		$data = ob_get_clean();
		echo "Ok\n";
		file_put_contents("txt/{$file}.txt", $data);
	}
?>