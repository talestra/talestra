<?php
	function freadsz($f) {
		$s = '';
		while (!feof($f)) {
			$c = fread($f, 1);
			if ($c == "\0") break;
			$s .= $c;
		}
		return $s;
	}
	function extractPack($pack) {
		$path = "Data/{$pack}";
		@mkdir($path, 0777);
		$f = fopen("Data/{$pack}.pck", 'rb');
		$header = fread($f, 6);
		list(,$start, $len) = unpack('V2', fread($f, 8));
		fseek($f, $start - 1);
		while (!feof($f)) {
			@list(, $file_pos, $file_size_c) = unpack('V2', fread($f, 8));
			$file_name   = freadsz($f);
			$file_time0  = freadsz($f);
			$file_size_u = freadsz($f);
			$file_time1  = freadsz($f);
			if (feof($f)) break;

			$file_out = "{$path}/{$file_name}";
			echo "{$file_out}...";
			printf("%08X...", $file_pos);
			
			if (!file_exists($file_out)) {
				$bpos = ftell($f);
				{
					fseek($f, $file_pos - 1);
					list(,$file_size2) = unpack('V', fread($f, 4));
					printf("%08X...", $file_size2);
					$data_u = gzuncompress(fread($f, $file_size_c));
					//$data_u = gzinflate($data_c);
					file_put_contents($file_out, $data_u);
					unset($data_c);
					unset($data_u);
				}
				fseek($f, $bpos);
				echo "Ok\n";
			} else {
				echo "Exists\n";
			}
		}
	}
	function extractPacks() {
		extractPack('Anime');
		extractPack('Common');
		extractPack('Data');
		extractPack('Frames');
		extractPack('Images');
		extractPack('Music');
		extractPack('Install');
		//extractPack('Jast');
		//extractPack('System');
	}
	function extractDisk() {
		$f = fopen('Data/Scratch.dsk', 'rb');
		$d = fread($f, 999999);
		gzuncompress(substr($d, 10));
		//Scratch.dsk
	}
	extractPacks();
	//extractDisk();
?>