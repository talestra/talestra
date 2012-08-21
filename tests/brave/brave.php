<?php

function decrypt_data_rr($cl, $dl) {
	return ~($cl & $dl) & ($cl | $dl);
}

function decrypt_data($data) {
	static $key = [
		0x23, 0xA0, 0x99, 0x50, 0x3B, 0xA7, 0xB9, 0xB6, 0xE1, 0x8E, 0x92, 0xF9,
		0xF4, 0xFC, 0x3D, 0xE8, 0x71, 0xF9, 0xF4, 0x28, 0xE6, 0xE7, 0xE8, 0x38,
		0x33, 0x06, 0x0B, 0x04, 0x0B, 0x03
	];
	$keyCount = count($key);
	
	$bl = 0;
	$dt = 0;
	

	for ($n = 0; $n < strlen($data); $n++) {
		$keyOffset = ($n + $bl) % $keyCount;
		$dataByte = ord($data[$n]);
		
		$cryptByte = $key[$keyOffset] | ($bl & $dt);
		
		$data[$n] = chr(decrypt_data_rr($dataByte, $cryptByte));
		
		if ($keyOffset == 0) {
			
			$bl = $key[($bl + $dt) % $keyCount];
			$dt++;
		}
	}
	
	return $data;
}

$gameFolder = 'c:/juegos/brave_s';

foreach (glob("{$gameFolder}/scenario/*.dat") as $fileIn) {
	if (substr($fileIn, -4) != '.dat') continue;

	$fileOut = substr($fileIn, 0, -4) . '.scr';
	
	echo "{$fileIn} -> {$fileOut}\n";

	file_put_contents($fileOut, decrypt_data(file_get_contents($fileIn)));

}

