<?php

// 0x00..0x1D

$key = [
	0x23, 0xA0, 0x99, 0x50, 0x3B, 0xA7, 0xB9, 0xB6, 0xE1, 0x8E, 0x92, 0xF9,
	0xF4, 0xFC, 0x3D, 0xE8, 0x71, 0xF9, 0xF4, 0x28, 0xE6, 0xE7, 0xE8, 0x38,
	0x33, 0x06, 0x0B, 0x04, 0x0B, 0x03
];

$data = file_get_contents('c:/juegos/brave_s/save/system.sav');


function decrypt_rr($cl, $dl) {
	return ~($cl & $dl) & ($cl | $dl);
}

$out = '';

$bl = 0;
$dt = 0;

for ($n = 0; $n < strlen($data); $n++) {
	$keyOffset = ($n + $bl) % count($key);
	$dataByte = ord($data[$n]);
	
	$cryptByte = $key[$keyOffset] | ($bl & $dt);
	
	$data[$n] = chr(decrypt_rr($dataByte, $cryptByte));
	
	if ($keyOffset == 0) {
		
		$bl = $key[($bl + $dt) % count($key)];
		$dt++;
	}
}

file_put_contents('temp.bin', $data);
