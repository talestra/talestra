<?php
	function fwrite4($f, $v) { return fwrite($f, pack('N', $v)); }
	function fread4($f) { return ($a = unpack('N', fread($f, 4))) ? $a[1] : false; }
	
    if (!function_exists('fnmatch')) {
        function fnmatch($pattern, $string) {
            return @preg_match(
                '/^' . strtr(addcslashes($pattern, '/\\.+^$(){}=!<>|'),
                array('*' => '.*', '?' => '.?')) . '$/i', $string
            );
        }
    }
		
	function process_text($t) {
		$r = '';
		$code = false;
		$lc = false;
		for ($n = 0, $l = strlen($t); $n <= $l; $n++) {
			$c = ($n < $l) ? substr($t, $n, 1) : ' ';
			if (ord($c) < 0x20 || $c == '}' || $c == '<' || $c == '>' || ord($c) > 0x7F) {
				if (!$code) {
					$code = true;
					$r .= '<';
				}
				$r .= sprintf('%02X', ord($c));
				$lc = ord($c);
			} else {
				if ($code) {
					$code = false;
					$r .= '>';
					if ($lc == 0x18) $r .= "\n";
				}
				if ($n < $l) $r .= $c;
			}
		}
		return $r;
	}
	
	function unprocess_text($t) {
		$r = '';
		for ($n = 0, $l = strlen($t); $n < $l; $n++) {
			$c = $t[$n];
			if ($c != '<') { $r .= $c; continue; }
			
			$n++;
			while ($n < $l) {
				$c = $t[$n];
				if ($c == '>')  break;
				$r .= chr(hexdec(substr($t, $n, 2)));
				$n += 2;
			}
		}
		return $r;
	}
	
	class MsgFile {
		public $base;
		public $basepointers;
		public $text;
		public $extradata;
	
		static function fromFile($file) {				
			if (!($f = fopen($file, 'rb'))) throw(new Exception('Error al abrir el fichero'));
			
			$msg = new MsgFile;
			
			fseek($f, $base = fread4($f));
			
			$count = (($back = fread4($f)) / 4) - 1;
			
			$pointers = array();
			
			for ($n = 0; $n < $count; $n++) {
				$next = fread4($f);
				$len = $next - $back;		
				$pointers[] = array($back + $base, $len);
				$back = $next;
			}
			
			$msg->text = array();
			
			foreach ($pointers as $k => $pointer) {
				list($pos, $len) = $pointer;
				fseek($f, $pos);
				$text = ($len != 0) ? fread($f, $len) : '';
				//$msg->text[$k] = process_text($text);
				$msg->text[$k] = $text;
			}			
		
			$msg->base = $base;
			$count = ($base - 4) / 4;
			fseek($f, 4);
			$msg->basepointers = array(0);
			$pbase = fread4($f);
			for ($n = 1; $n < $count; $n++) {
				$msg->basepointers[] = fread4($f) - $pbase;
			}
			fseek($f, $pbase);
			$msg->extradata = '';
			while (!feof($f)) $msg->extradata .= fread($f, 0x1000);
			
			//$msg->extradata = strlen($msg->extradata);
			
			fclose($f);
			
			return $msg;
		}
		
		function exportPointers($file) {
			if (!($f = fopen($file, 'wb'))) throw(new Exception('Error al abrir el fichero'));
			ksort($this->text);
			foreach ($this->text as $k => $v) {
				if (!strlen($v)) continue;
				fprintf($f, "## POINTER %d\n%s\n\n", $k, process_text($v));
			}
			fclose($f);
		}
		
		function importPointers($file) {
			if (!($f = fopen($file, 'rb'))) throw(new Exception('Error al abrir el fichero'));
			$k = null;
			while (!feof($f)) {
				if (!strlen($line = trim(fgets($f)))) continue;
				if (substr($line, 0, 2) == '##') {
					if (!preg_match('/\\d+/', $line, $res)) continue;
					$k = $res[0];					
					$this->text[$k] = '';
					continue;
				}
				if (!isset($k)) throw(new Exception("Fichero inválido"));
				$this->text[$k] .= unprocess_text($line);
			}
			fclose($f);
		}
		
		function save($file) {
			if (!($f = fopen($file, 'wb'))) throw(new Exception('Error al abrir el fichero'));
			
			// pbase es la base de los punteros
			// tbase es la base del texto
			fwrite4($f, $pbase = $this->base);
			$tbase = $this->base + (sizeof($this->text) + 1) * 4;
			
			fseek($f, $tbase);
					
			// Nos aseguramos de que el texto está en orden
			ksort($this->text);
			
			foreach ($this->text as $k => $t) {
				$pback = ftell($f);
				
				if (true) {
					fseek($f, $pbase + ($k * 4));
					fwrite4($f, $pback - $pbase);
				}
				
				fseek($f, $pback);
			
				fwrite($f, $t);
			}
			
			// Escribimos el puntero final
			$end = ftell($f);
			
			fwrite($f, "\0");

			// Escribimos el resto de datos
			fwrite($f, $this->extradata);
			
			fseek($f, $pbase + sizeof($this->text) * 4);
			fwrite4($f, $end - $pbase);
					
			fseek($f, 4);
			foreach ($this->basepointers as $p) fwrite4($f, $p + $end + 1);
					
			fclose($f);
		}
	}	
	
	$patterns = array(
		'*.msg',
		'winmsg.bin',
		'clefmes.bin',
		'itemmes.bin',
	);	
	
	
	function process_dir($callback, $rpath, $path = '') {
		global $patterns;
		$rpath = realpath($rpath);
		if (!($dir = opendir($rpath))) {
			printf("Error al abrir '%s'\n", $rpath);
			return;
		}
		
		while (($file = readdir($dir)) !== false) {
			if ($file == '.' || $file == '..') continue;			
			$rfile = $rpath . '/' . $file;			
			
			if (is_dir($rfile)) {
				process_dir($callback, $rpath . '/' . $file, $file . '/');
			} else {
				$pass = false;
				foreach ($patterns as $pattern) {
					if (fnmatch($pattern, $file)) {
						$pass = true;
						break;
					}					
				}
				
				if ($pass) {
					$pname = str_replace('/', '_', $path) . $file . '.txt';					
					$callback($file, $rfile, $pname);					
				}
			}
		}
		
		closedir($dir);
	}	
?>