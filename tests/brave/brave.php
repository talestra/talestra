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

function extractScale($v, $offset, $count, $to) {
	$mask = ((1 << $count) - 1);
	//printf("%d\n", $mask);
	return ((($v >> $offset) & $mask) * $to) / $mask;
}

function decodeImage($f) {
	static $key1 = [0x84, 0x41, 0xDE, 0x48, 0x08, 0xCF, 0xCF, 0x6F, 0x62, 0x51, 0x64, 0xDF, 0x41, 0xDF, 0xE2, 0xE1];

	//$f = fopen('PT_LOGO.CRP.u', 'rb');
	//$f = fopen('P_CURSOR.CRP.u', 'rb');
	$magic = fread($f, 14);
	if ($magic != "(C)CROWD ARPG\0") throw(new Exception("Invalid file '{$magic}'"));
	$key    = fread($f, 0x08);
	$header = fread($f, 0x10);

	//printf("----------------\n");

	// STEP1
	for ($n = 0; $n < 0x10; $n++) {
		$v2 = decrypt_data_rr($key1[$n], ord($header[$n]));
		//printf("%02X -> %02X\n", ord($header[$n]), $v2);
		$header[$n] = chr($v2);
	}

	//printf("----------------\n");

	// STEP2
	for ($n = 0; $n < 0x10; $n++) {
		$v2 = decrypt_data_rr(ord($header[$n]), ord($key[$n % 8]));
		//printf("%02X -> %02X\n", ord($header[$n]), $v2);
		$header[$n] = chr($v2);
	}

	//printf("----------------\n");

	list(,$width, $height, $skip) = unpack('V3', $header);

	//printf("%d, %d, %d\n", $width, $height, $skip);

	fseek($f, $skip, SEEK_CUR);

	// INT32 : Width
	// INT32 : Height
	// INT32 : Skip

	$i = imagecreatetruecolor($width, $height);
	$data = fread($f, $width * $height * 2);
	$n = 0;
	for ($y = 0; $y < $height; $y++) {
		for ($x = 0; $x < $width; $x++) {
			list(,$pixelData) = unpack('v', substr($data, $n * 2, 2));
			$b = extractScale($pixelData, 0, 5, 255);
			$g = extractScale($pixelData, 5, 6, 255);
			$r = extractScale($pixelData, 11, 5, 255);
			//printf("%04X, %d, %d, %d\n", $pixelData, $r, $g, $b);
			imagesetpixel($i, $x, $y, imagecolorallocate($i, $r, $g, $b));
			$n++;
		}
	}

	//imagepng($i, 'test.png');
	return $i;
}

$gameFolder = 'c:/juegos/brave_s';

foreach (glob("{$gameFolder}/scenario/*.dat") as $fileIn) {
	$fileOut = substr($fileIn, 0, -4) . '.scr';
	
	echo "{$fileIn} -> {$fileOut}\n";

	if (!file_exists($fileOut)) {
		file_put_contents($fileOut, decrypt_data(file_get_contents($fileIn)));
	}
}

foreach (glob("{$gameFolder}/map/*.dat") as $fileIn) {
	$fileOut = substr($fileIn, 0, -4) . '.scr';
	
	echo "{$fileIn} -> {$fileOut}\n";

	if (!file_exists($fileOut)) {
		file_put_contents($fileOut, decrypt_data(file_get_contents($fileIn)));
	}
}

foreach (glob("{$gameFolder}/parts/*.CRP") as $fileIn) {
	$fileOut1 = substr($fileIn, 0, -4) . '.CRP.u';
	$fileOut2 = substr($fileIn, 0, -4) . '.PNG';
	
	echo "{$fileIn} -> {$fileOut2}\n";
	
	if (!file_exists($fileOut2)) {
		`ms-expand.exe {$fileIn} {$fileOut1}`;
		imagepng(decodeImage(fopen($fileOut1, 'rb')), $fileOut2);
	}
}
