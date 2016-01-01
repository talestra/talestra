<?php
	function extract_vol($vol) {
		list($name) = explode('.', $vol);
		$f = fopen($vol, 'rb');
		$vs = array();
		while (!feof($f)) {
			list(,$v) = unpack('V', fread($f, 4));
			if ($v == 0) break;
			$vs[] = $v;
		}
		$count = sizeof($vs) - 1;
		@mkdir("VOL/{$name}", 0777, true);
		for ($n = 0; $n < $count; $n++) {
			fseek($f, $vs[$n]);
			$size = $vs[$n + 1] - $vs[$n];
			$data = '';
			if ($size > 0) $data = fread($f, $size);
			file_put_contents(sprintf("VOL/{$name}/%02d", $n), $data);
		}
		fclose($f);
		//print_r($vs);
	}
	
	foreach (scandir('.') as $f) {
		if (strtoupper(substr($f, -4, 4)) == '.VOL') {
			extract_vol($f);
		}
	}
?>