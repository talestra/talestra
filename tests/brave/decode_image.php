<?php

$i = imagecreatetruecolor(640, 480);

function extractScale($v, $offset, $count, $to) {
	$mask = ((1 << $count) - 1);
	//printf("%d\n", $mask);
	return ((($v >> $offset) & $mask) * $to) / $mask;
}

$data = file_get_contents('test_color.bin');
$n = 0;
for ($y = 0; $y < 480; $y++) {
	for ($x = 0; $x < 640; $x++) {
		list(,$pixelData) = unpack('v', substr($data, $n * 2, 2));
		$b = extractScale($pixelData, 0, 5, 255);
		$g = extractScale($pixelData, 5, 6, 255);
		$r = extractScale($pixelData, 11, 5, 255);
		//printf("%04X, %d, %d, %d\n", $pixelData, $r, $g, $b);
		imagesetpixel($i, $x, $y, imagecolorallocate($i, $r, $g, $b));
		$n++;
	}
}

imagepng($i, 'test.png');