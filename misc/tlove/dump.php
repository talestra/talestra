<?php
	@mkdir('DUMP');
	
	function dump($file) {
		$f = fopen($file, 'rb');
		list(,$last) = unpack('v', fread($f, 2));
		$files = array();
		while (true) {
			$name = rtrim(fread($f, 0xC), "\0");
			list(,$size) = unpack('V', fread($f, 4));
			if (sizeof($files)) {
				$files[sizeof($files) - 1][2] = $size - $files[sizeof($files) - 1][1];
			}
			if (!strlen($name)) break;
			$files[] = array($name, $size, 0);
		}
		fclose($f);
		@mkdir($path = 'DUMP/' . $file);
		foreach ($files as $key) {
			file_put_contents("{$path}/{$key[0]}", file_get_contents($file, false, null, $key[1], $key[2]));
		}
	}
	
	dump('MIDI');
	dump('DATE');
	dump('DATG');
	dump('EFF');
	dump('MRS');
?>