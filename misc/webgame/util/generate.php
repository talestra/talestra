<?php
	function imageflipx($i) {
		//$ri = imagecreatetruecolor($w = imageSX($i), $h = imageSY($i));
		$ri = imagecreate($w = imageSX($i), $h = imageSY($i));
		
		imagecolortransparent($ri, $trans = imagecolorallocate($ri, 0xFF, 0xFF, 0xFF));

		for ($x = 0; $x < $w; $x++) {
			imagecopy($ri, $i, $w - $x - 1, 0, $x, 0, 1, $h);
		}

		return $ri;
	}

	function imagesub($i, $x, $y, $w, $h) {
		list($iw, $ih) = array(imageSX($i), imageSY($i));

		if ($x < 0) { $w += $x; $x = 0; }
		if ($y < 0) { $h += $y; $y = 0; }

		//if ($x >= $iw || $y >= $ih) return imagecreate(0, 0);

		if ($x + $w >= $iw) $w = $iw - $x;
		if ($y + $h >= $ih) $h = $ih - $y;

		//$ri = imagecreatetruecolor(max($w, 1), max($h, 1));
		$ri = imagecreate(max($w, 1), max($h, 1));
		
		imagecolortransparent($ri, $trans = imagecolorallocate($ri, 0xFF, 0xFF, 0xFF));

		imagecopy($ri, $i, 0, 0, $x, $y, $w, $h);

		return $ri;
	}

	function imageput($src, $dst, $x, $y) {
		imagecopy($dst, $src, $x, $y, 0, 0, imageSX($src), imageSY($src));
	}

	// w:24 h:48

	for ($n = 1; $n <= 7; $n++) {
		$file = sprintf('%04d', $n);

		$i1 = imagecreatefromgif("{$file}.gif");
		$i2 = imagecreatetruecolor(18 * 24, 48 * 5);
		
		//imagefilledrectangle($i2, 0, 0, imageSX($i2), imageSY($i2), imagecolorallocate($i2, 0xFF, 0xFF, 0xFF));
		imagefilledrectangle($i2, 0, 0, imageSX($i2), imageSY($i2), imagecolorallocate($i2, 0x00, 0x00, 0x00));
		//imagefilledrectangle($i2, 0, 0, imageSX($i2), imageSY($i2), imagecolorallocate($i2, 0xFF, 0x00, 0x00));
		
		//imagecopyresized($i2, $i1, 0, 0, 50, 50, 100, 100, 100, 100);

		for ($y = 0; $y < 5; $y++) {
			for ($x = 0; $x < 10; $x++) {
				$ci = imagesub($i1, $x * 24, $y * 48, 24, 48);
				imageput($ci, $i2, $x * 24, $y * 48);
			}
		}

		// Andando
		for ($y = 0; $y < 3; $y++) {
			for ($x = 0; $x < 5; $x++) {
				$ci = imagesub($i1, ($x + 5) * 24, $y * 48, 24, 48);
				imageput(imageflipx($ci), $i2, ($x + 10) * 24, $y * 48);
			}
		}

		// Parado
		$y = 2;
		for ($x = 0; $x < 3; $x++) {
			$ci = imagesub($i1, ($x + 1) * 24, $y * 48, 24, 48);
			imageput(imageflipx($ci), $i2, ($x + 15) * 24, $y * 48);
		}

		// Corriendo (1)
		$y = 3;
		for ($x = 0; $x < 6; $x++) {
			$ci = imagesub($i1, ($x + 3) * 24, $y * 48, 24, 48);
			imageput(imageflipx($ci), $i2, ($x + 10) * 24, $y * 48);
		}

		// Corriendo (2)
		$y = 4;
		for ($x = 0; $x < 3; $x++) {
			$ci = imagesub($i1, ($x + 3) * 24, $y * 48, 24, 48);
			imageput(imageflipx($ci), $i2, ($x + 10) * 24, $y * 48);
		}

		imagepng($i2, 'out.png');

		system('nconvert -out bmp out.png > NUL 2> NUL 3> NUL');
		unlink('out.png');
		system('hq2x out.bmp out2x.bmp > NUL 2> NUL 3> NUL');
		unlink('out.bmp');
		//system('nconvert -resize 75% 75% -out png out2x.bmp > NUL 2> NUL 3> NUL');
		//unlink('out2x.bmp');
		@unlink("{$file}.bmp");
		rename('out2x.bmp', "{$file}.bmp");
		//exit;
	}
?>