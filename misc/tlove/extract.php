<?php
	function fread2($f) { list(,$v) = unpack('v', fread($f, 2)); return $v; }
	function fread4($f) { list(,$v) = unpack('V', fread($f, 4)); return $v; }
	
	function pak_extract_real($file, $list) {
		$f = fopen($file, 'rb');
		@mkdir("{$file}.d", 0777);
		echo "{$file}\n";
		foreach ($list as $element) {
			list($name, $pos, $len) = $element;
			fseek($f, $pos);
			echo "  {$name}...";
			file_put_contents("{$file}.d/{$name}", fread($f, $len));
			echo "Ok\n";
		}
		fclose($f);
	}
	
	function pak_extract($file) {
		$f = fopen($file, 'rb');
		$count = fread2($f) / 0x10;
		$l_pos = $l_name = array();
		for ($n = 0; $n < $count; $n++) {
			$name = rtrim(fread($f, 12), "\0");
			$pos = fread4($f);
			$l_name[] = $name;
			$l_pos[] = $pos;
		}
		fclose($f);
		//array_pop($l_name);
		$list = array();
		for ($n = 0, $l = count($l_name) - 1; $n < $l; $n++) {
			$list[] = array($l_name[$n], $l_pos[$n], $l_pos[$n + 1] - $l_pos[$n]);
		}
		pak_extract_real($file, $list);
		//print_r($list);
		/*
		$data = fread($f, );
		fread($f);
		*/
	}
	
	pak_extract('DATE');
	pak_extract('DATG');
	pak_extract('EFF');
	pak_extract('MIDI');
	pak_extract('MRS');
?>