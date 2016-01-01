<?php

// tokimeki memorial girl's side

function fread1($f) { list(,$v) = unpack('C', fread($f, 1)); return $v; }
function fread2($f) { list(,$v) = unpack('v', fread($f, 2)); return $v; }
function fread3($f) { list(,$v) = unpack('V', fread($f, 3) . "\0"); return $v; }

$f = fopen('A01_00_000', 'rb');
//$f2 = fopen('A01_00_000.u_', 'wb');

$magic = fread1($f);
$unsize = fread3($f);
//printf("%08X\n", $unsize);

$debug = 0;
//$debug = 1;
//$debug = 2;

$data = '';

while (!feof($f)) {
	//if (ftell($f) > 0x20) break;
	if (strlen($data) >= $unsize) break;
	
	$code = fread1($f);
	for ($n = 7; $n >= 0; $n--) {
		if (strlen($data) >= $unsize) break;
	
		$compressed = ($code & (1 << $n)) != 0;
		if ($compressed) {
			if ($debug == 1) echo 'd';
			//$d = fread2($f);
			$d1 = fread1($f);
			$d2 = fread1($f);
			
			$pos = (($d2 << 0) | (($d1 & 0x0F) << 8));
			$size = ($d1 >> 4) + 3;
			
			//$size = ($d >> 8) & 0x0F;
			//$pos = ($d & 0x00FF) | ($d >> 4) & 0x0F00;

			$rpos = strlen($data) - $pos - 1;

			if ($debug == 2) {
				@printf("%02X%02X:pos=%d,size=%d,total=%d,rpos=%d\n", $d1, $d2, $pos, $size, strlen($data), $rpos);
			}
			
			if ($debug == 2) printf("Copying:");
			for ($m = 0; $m < $size; $m++) {
				$b = substr($data, $rpos + $m, 1);
				
				$data .= $b;
				//fwrite($f2, $b);
				if ($debug == 2) printf("%02X,", ord($b));
				if (strlen($data) >= $unsize) break;
			}
			if ($debug == 2) printf("\n");
			
		} else {
			if ($debug == 1) echo 'u';
			$d = fread1($f);
			$data .= chr($d);
			//fwrite($f2, chr($d));
			if ($debug == 2) printf("%02X\n", $d);
		}
	}
	if ($debug == 1) echo '.';
	if ($debug == 2) echo "--\n";
}

file_put_contents('A01_00_000.u_', $data);