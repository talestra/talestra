<?php
	require_once('common.php');

	function do_reinsert($n, $p) {
		$error = false;
		echo "Extrayendo '$n'... ";
		$image_in     = isset($p['data'] ) ? (EXTRACT_RAW . '/' . $p['data' ]) : false;
		$image_pal    = isset($p['color']) ? (EXTRACT_RAW . '/' . $p['color']) : false;

		$image_mod_out = REINSERT_PNG . '/' . $n . '.png';
		//$image_mod_out = 'png/' . $n . '.png';
		$image_mod_in  = isset($p['data'] ) ? (REINSERT_RAW . '/' . $p['data' ]) : false;
		$image_mod_pal = isset($p['color']) ? (REINSERT_RAW . '/' . $p['color']) : false;

		$image_colors = isset($p['bpp']) ? pow(2, $p['bpp']) : false;
		$image_bpp    = isset($p['bpp']) ? $p['bpp'] : 8;
		$image_width  = isset($p['width']) ? $p['width'] : false;
		$image_height = isset($p['height']) ? $p['height'] : false;
		$image_mode   = isset($p['modo']) ? $p['modo'] : 2;
		$image_tiles  = isset($p['tiles']) ? $p['tiles'] : '8x8';

		// Obtenemos los datos
		$slice = isset($p['slice']) ? explode('-', $p['slice']) : '';
		for ($n = 0; $n < 2; $n++) if (!isset($slice[$n])) $slice[$n] = '';
		$slice[0] = trim($slice[0]); $slice[1] = trim($slice[1]);
		if (!strlen($slice[0])) $slice[0] = 0;
		if (!strlen($slice[1])) $slice[1] = filesize($image_in);
		//$d = file_get_contents($image_in, false, NULL, $slice[0], $slice[1] - $slice[0]);
		$d = file_get_contents($image_in, false, NULL, getInteger($slice[0]), getInteger($slice[1]));

		printf("SLICE(%s:%08X-%08X) ", $image_in, getInteger($slice[0]), getInteger($slice[1]));

		$image_size = strlen($d);

		$image_pixels = ($image_size << 3) / $image_bpp;

		$image_height2 = $image_pixels / $image_width;
		if (!$image_height) {
			$image_height = $image_height2;
		} else if ($image_height2) {
			$error = true;
			fprintf(STDERR, "ERROR: La altura de la imagen no coincide con la calculada " . $image_height . " != " . $image_height2 . "\n");
		}


		list($w, $h) = array($image_width, $image_height);

		echo "({$w}x{$h}) ";
		echo "(C:$image_colors) ";

		//if (!($i = imagecreate($w, $h))) return;
		if (!($i = imagecreatefrompng($image_mod_out))) return;

		if (!file_exists($image_mod_in)) {
			copy($image_in, $image_mod_in);
		}

		if ($image_pal) {
			copy($image_pal, $image_mod_pal);
			if ($f = fopen($image_mod_pal, 'r+b')) {
				fwrite($f, palette::reinsert($i));
				fclose($f);
			}
			//palette::extract($i, file_get_contents($image_pal));
		} else {
			//palette::usegrays($i, $image_colors);
			//fprintf(STDERR, "TODO: " . __LINE__ . "\n");
		}

		$bpp = $image_bpp;
		$mask = (1 << $image_bpp) - 1;
		$bp = 8 / $bpp;

		printf("(BPP:%d, MASK:%08b, BP:%d) ", $bpp, $mask, $bp);

		if ($image_height != (int)$image_height) {
			$error = true;
			fprintf(STDERR, "\nERROR: La altura tiene decimales, posiblemente el ancho es incorrecto... ");
		}

		$r = isset($p['reversed']) ? (bool)$p['reversed'] : false;

		printf("REV(%d) ", $r);

		$image_blank_list = array();
		if (isset($p['blank'])) {
			$image_blank_list = array_flip(explode(';', str_replace(' ', '', $p['blank'])));
			echo "(BLANK: " . $p['blank'] . ')';
			printf("\n");
			//print_r($image_blank_list);
		}

		switch ($image_mode) {
			case 1:
				$bp_w = $bp_h = 8;

				list($wbb, $hbb) = explode('x', $image_tiles);
				list($be_w, $be_h) = array($w / $wbb, $h / $hbb);
				list($bi_w, $bi_h) = array($wbb / $bp_w, $hbb / $bp_h);

				printf('TILES(%dx%d) BLOCK_EXT(%dx%d) BLOCK_INT(%dx%d) TILES(%dx%d) GROUP:%s) ', $wbb, $hbb, $be_w, $be_h, $bi_w, $bi_h, $bp_w, $bp_h, $image_tiles);

				if (isset($p['blank'])) echo "\n";

				$n = 0;

				for ($be_y = 0; $be_y < $be_h; $be_y++) for ($be_x = 0; $be_x < $be_w; $be_x++) {
					if (isset($image_blank_list[$be_x . ',' . $be_y])) {
						echo "Skipping: {$be_x},{$be_y}\n";
						continue;
					}

					for ($bi_y = 0; $bi_y < $bi_h; $bi_y++) for ($bi_x = 0; $bi_x < $bi_w; $bi_x++) {
						//echo $be_x . ',' . $be_y . "\n";
						//if ($be_y >= 2 && $be_x == 7) continue;
						for ($y = 0; $y < $bp_h; $y++) for ($x = 0; $x < $bp_w; $x += $bp, $n++) {
							$c = 0;
							//echo $n . "\n";
							for ($m = 0; $m < $bp; $m++) {
								$c <<= $bpp;
								$c |= imagecolorat($i,
									($be_x * $wbb) + ($bi_x * $bp_w) + $x + $m,
									($be_y * $hbb) + ($bi_y * $bp_h) + $y
								) & $mask;
							}
							if ($r) $c = (($c & 0xF) << 4) | (($c >> 4) & 0xF);
							$d{$n} = chr($c);
						}
					}
				}
			break;
			case 2:
				for ($y = 0, $n = 0; $y < $h; $y++) {
					for ($x = 0; $x < $w; $x += $bp, $n++) {
						$c = 0;
						for ($m = 0; $m < $bp; $m++) {
							//$c <<= $bpp; $c |= imagecolorat($i, $x + $m, $y) & $mask;
							$c >>= $bpp; $c |= (imagecolorat($i, $x + $m, $y) & $mask) << (8 - $bpp);
						}
						if ($r) $c = (($c & 0xF) << 4) | (($c >> 4) & 0xF);
						$d{$n} = chr($c);
					}
				}
				//echo $d;
			break;
			default:
				$error = true;
				fprintf(STDERR, "\nERROR: MODO {$image_mode} no soportado ");
			break;
		}

		if ($f = fopen($image_mod_in, 'r+b')) {
			fseek($f, getInteger($slice[0]));
			fwrite($f, substr($d, 0, getInteger($slice[1])));
			fclose($f);
		}

		echo $error ? "Error\n" : "Ok\n";

		return !$error;
	}

	perform('do_reinsert');
?>