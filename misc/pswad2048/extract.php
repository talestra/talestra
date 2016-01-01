<?php
	function fread4($f) { return array_pop(unpack('V', fread($f, 4)));; }
	
	function ExtractFile($pname) {
		$f = fopen($pname, 'rb');
		fseek($f, 0x0c);
		$last = fread4($f);
		fseek($f, 0x20);
		$files = array();
		while (ftell($f) < $last) {
			list($name) = explode("\0", fread($f, 0xC));
			$start  = fread4($f);
			$length = fread4($f);
			$files[] = array($name, $start, $length);
		}
		foreach ($files as $file) {
			list($name, $start, $length) = $file;
			$path = "EXTRACT/{$pname}"; $fname = "{$path}/{$name}";
			fseek($f, $start);
			printf("%s...%d\n", $fname, $start);
			if (file_exists($fname)) continue;
			@mkdir($path, 0777);
			file_put_contents($fname, fread($f, $length));
		}
	}
	
	function Decrypt2(&$s, $start, $end, $d) {
		$dl = strlen($d);
		for ($n = $start; $n < $end; $n++) $s{$n} = chr(ord($s{$n}) ^ ord($d{($n - $start) % $dl}));
	}
	
	function Decrypt($file, $file_out) {
		if (fread(fopen($file, 'rb'), 8) != 'GGPFAIKE') {
			@unlink($file_out);
			echo('not GGPFAIKE...');
			return;
		}
		
		if (file_exists($file_out)) return;
		
		$data = file_get_contents($file);
		
		list(,$v1_x, $v2_x) = unpack('V2', substr($data, 0x0, 0x0 + 8));
		list(,$v1_v, $v2_v) = unpack('V2', substr($data, 0xC, 0xC + 8));
		
		if ($v1_v == 0) {
			die('error!');
		}
		
		$data = substr_replace($data, pack('VV', ($v1_v ^ $v1_x), ($v2_v ^ $v2_x)), 0xC, 8);

		list(,$start, $length) = unpack('V2', substr($data, 0x14, 8));
		
		@Decrypt2($data, $start, $start + $length, substr($data, 0xC, 8));
		
		//file_put_contents('1.png', substr($data, $start, $length));
		//file_put_contents('1.png', $data);
		
		file_put_contents($file_out, substr($data, $start, $length));
	}
	
	if (false) {
		ExtractFile('DATA');
		ExtractFile('GGD');
		ExtractFile('ISF');
		ExtractFile('SE');
		ExtractFile('VOICE1');
		ExtractFile('WMSC');
	}
	
	//ExtractFile('GGD');
	
	//Decrypt(file_get_contents('EXTRACT/GGD/M_WIN.GGP'));
	foreach (scandir($path = 'EXTRACT/GGD') as $f) { $rf = "{$path}/{$f}";
		if (is_dir($rf)) continue;
		echo "$f...";
		Decrypt($rf, "EXTRACT/GGD.PNG/{$f}.PNG");
		echo "OK\n";
	}
?>