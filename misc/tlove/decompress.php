<?php
	function fread1($f) { @list(, $r) = unpack('C', fread($f, 1)); return $r; }
	function fread2($f) { @list(, $r) = unpack('v', fread($f, 2)); return $r; }
	function fread4($f) { @list(, $r) = unpack('V', fread($f, 4)); return $r; }
	function freadsz($f, $l) { return rtrim(fread($f, $l), "\0"); }
	function error($s = 'error') { throw(new Exception($s)); }

	function imagefrommrs($filename) {
		$f = fopen($filename, 'rb');
		
		if (fread($f, 4) != "CD\0\0") {
			//error("Invalid image file");
		}
		
		$width = fread2($f);
		$height = fread2($f);
		//echo "Image({$width}x{$height})\n";
		
		fseek($f, 7 - 3, SEEK_CUR); // skip

		//$width = 256;
		//$height = 1000;

		$i = imagecreate($width, $height);
		
		$cols = array();
		for ($n = 0; $n < 256; $n++) {
			@list(, $b, $r, $g) = unpack('C3', fread($f, 3));
			$cols[$n] = imagecolorallocate($i, $r, $g, $b);
			//imagecolorset($i, $n, $r, $g, $b);
			//print_r($v);
		}
		
		$out = '';
		
		$debug = true;
		$debug_count = 130;
		
	/*
	0048E1 | 000401: REPEAT BYTE(00) TIMES(2)
	0048E3 | 000404: REPEAT BYTE(D8) TIMES(224)
	0049C3 | 000407: REPEAT PATTERN OFFSET(179) LENGTH(202)
	----
	0048E1 | 000401: REPEAT BYTE(00) TIMES(2)
	0048E3 | 000404: REPEAT BYTE(D8) TIMES(224)
	0049E7
	*/
		
		// 2B00
		// 48E0
		
		$debug = false;
		
		$size = $width * $height;
		
		try {
			while (!feof($f)) {
				if (strlen($out) >= $size) break;
				if ($debug) {
					if ($debug_count-- <= 0) break;
				}
				$c = fread1($f);
				if ($c & 0xC0) { // 11000000
					if ($c & 0x80) { // 10000000
						//echo $out;
						//exit;
						$c2  = fread1($f);
						$c  &= 0x7F;
						$c2 &= 0xFF;
						
						$offset = (($c & 0xF) << 8) | $c2;
						$c3 = ($c >> 4) & 0xF;
						
						if ($c3) {
							$c3 += 2;
						} else {
							$c3  = fread1($f) + 0x0A;
						}
						
						if ($debug) {
							printf("%06X | %06X: REPEAT PATTERN OFFSET(%d) LENGTH(%d)\n", strlen($out), ftell($f), $c2, $c3);
						}
						//exit;
						
						while ($c3--) $out .= substr($out, -$offset - 1, 1);
						
						//printf("%02X %02X\n", $c, $c2); exit;
						//echo $c2; exit;
						
						//error('2');
					} else {
						$c &= 0x3F;
						if (!$c) {
							$c = fread1($f) + 0x40;
						} else {
							//$c += 1;
						}
						$c++;
						
						$c2 = substr($out, -1, 1);
						if ($debug) {
							printf("%06X | %06X: REPEAT LAST BYTE(%02X) TIMES(%d)\n", strlen($out), ftell($f), ord($c2), $c);
						}
						while ($c--) $out .= $c2;
					}
				} else {
					$c &= 0x3F; // 00111111
					if (!$c) $c = fread1($f) + 0x40;
					/*
					$c2 = fread($f, 1);
					if ($debug) {
						printf("%06X | %06X: REPEAT BYTE(%02X) TIMES(%d)\n", strlen($out), ftell($f), ord($c2), $c);
					}
					while ($c--) $out .= $c2;
					*/
					while ($c--) {
						$c2 = fread($f, 1);
						if ($debug) {
							printf("%06X | %06X: REPEAT BYTE(%02X) TIMES(%d)\n", strlen($out), ftell($f), ord($c2), $c);
						}
						$out .= $c2;
					}
				}
			}
			//fseek($f, 0, SEEK_END);
			file_put_contents('chunk.bin', fread($f, 1000));
			echo ftell($f);
		} catch (Exception $e) {
			echo "error: " . $e->getMessage() . "\n";
		}
		

		//file_put_contents('out.bin', $out);
		
		if (!$debug) {
			for ($y = 0, $n = 0; $y < $height; $y++) {
				for ($x = 0; $x < $width; $x++, $n++) {
					@imagesetpixel($i, $x + 0, $y + 0, ord($out[$n]));
				}
			}
			//imagepng($i, 'out.png');
		}
		
		return $i;
	}
	
	//imagefrommrs("MRS.d/AG020M.MRS");
	//exit;
	
	foreach (scandir('MRS.D') as $file) {
		if (substr($file, 0, 1) == '.') continue;
		if (substr($file, -4, 4) != '.MRS') continue;
		echo "{$file}...";
		if (file_exists("MRS.d/{$file}.PNG")){
			echo "Exists\n";
		} else {
			imagepng(imagefrommrs("MRS.d/{$file}"), "MRS.d/{$file}.PNG");
			echo "Ok\n";
		}
	}
	//imagepng(imagefrommrs('MRS.d/LOGO.MRS'), 'MRS.d/LOGO.PNG');
	//echo $out; 
?>