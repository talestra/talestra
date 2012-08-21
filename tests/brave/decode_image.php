<?php


function decrypt_data_rr($cl, $dl) {
	return ~($cl & $dl) & ($cl | $dl);
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
	if (fread($f, 14) != "(C)CROWD ARPG\0") throw(new Exception("Invalid file"));
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

$i = decodeImage(fopen('PT_LOGO.CRP.u', 'rb'));
imagepng($i, 'test.png');