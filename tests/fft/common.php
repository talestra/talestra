<?php
	function parse_list($file) {
		if (!($f = fopen($file, 'rb'))) return false;
		
		$csecn = '';
		
		$r = array();
		$in = false;
		
		while (!feof($f)){
			if (!strlen($l = trim(fgets($f)))) continue;
			
			switch (substr($l, 0, 1)) { case ';': case '#': continue; }
			
			if (substr($l, -1, 1) == '{') {
				$csecn = trim(substr($l, 0, -1));
				$csec = &$r[$csecn];
				$csec = array();
				$in = true;
			} else if ($in) {
				$pars = explode(':', $l, 2);
				if (sizeof($pars) == 2) $csec[strtolower(trim($pars[0]))] = trim($pars[1]);
			}
			
			if (substr($l, -1, 1) == '}') $in = false;
		}
		
		fclose($f);
		
		return $r;
	}
	
	function perform($callback) {
		global $list, $argv;
		$args = $argv;	
		array_shift($args);		
		
		$list = parse_list('images.lst');
		if (!$list) die("Hubo un error\n");
		
		function show_help() {
			global $list;
			
			echo "Ficheros:\n";
			echo implode(', ', array_keys($list));
			echo "\n";
			exit;
		}
		
		if (!sizeof($args)) show_help();
		
		$total = 0;
		$error = 0;
		
		foreach ($args as $ac) {
			
			if ($ac == '*') $ac = array_keys($list); else $ac = array($ac);						
			
			foreach ($ac as $c) {
				$cc = &$list[$c];
				
				if (!isset($cc)) {
					echo "No existe '{$c}'\n";
					continue;
				}
				
				try {
					if (!$callback($c, $cc)) $error++;
				} catch (Exception $e) {
					echo $e;
					$error++;
				}
				
				$total++;
			}
		}
		
		printf("----------------------\n");
		printf("Total procesados: %d\n", $total);
		printf("Total errores   : %d\n", $error);
	}
	
	class palette {
		static function extract($i, $d) {
			$cc = array();
			for ($n = 0, $l = (strlen($d) >> 1); $n < $l; $n++) {
				$c = self::decode(substr($d, $n << 1, 2));
				$cc[] = imagecolorallocate($i, $c[0], $c[1], $c[2]);
			}
			return $cc;
		}
		
		static function reinsert($i) {
			for ($d = '', $n = 0, $l = imagecolorstotal($i); $n < $l; $n++) $d .= self::encode(array_values(imagecolorsforindex($i, $n)));
			return $d;
		}
		
		static function usegrays($i, $l) {
			$cc = array();
			for ($n = 0, $l1 = $l - 1; $n < $l; $n++) {
				$c = $n * 255 / $l1;
				$cc[] = imagecolorallocate($i, $c, $c, $c);
			}
			return $cc;
		}
		
		static function decode($d) {
			list(,$c) = unpack('n', $d);			
			$r = (($c >>  0) & 0x1F) << 3;
			$g = (($c >>  5) & 0x1F) << 3;
			$b = (($c >> 10) & 0x1F) << 3;
			return array($r, $g, $b);
		}
		
		static function encode($cc) {
			$c = 0;
			$c |= (($cc[0] >> 3) & 0x1F) <<  0;
			$c |= (($cc[1] >> 3) & 0x1F) <<  5;
			$c |= (($cc[2] >> 3) & 0x1F) << 10;
			return pack('n', $c);
		}
	}
	
	function getInteger($v) {
		if (substr($v, 0, 2) == '0x') return base_convert(substr($v, 2), 16, 10);
		if (substr($v, 0, 2) == '0b') return base_convert(substr($v, 2),  2, 10);
		return (int)$v;
	}
?>