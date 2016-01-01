<?php
	class AREA {
		public $start = array();
		//public $end = array();
		
		function change_segment($ptr, $new_len, $new_ptr = null) {
			if (!isset($new_ptr)) $new_ptr = $ptr;
			
			if ($new_len <= 0) {
				$this->remove_segment($ptr);
				return;
			}
			
			$len = $this->start[$ptr];
			if ($ptr == $new_ptr) {
				$this->start[$ptr] = $new_len;
			} else {
				//unset($this->end[$ptr + $len]);
				//$this->end[$new_ptr + $new_len] = $new_ptr;
				unset($this->start[$ptr]);
				$this->start[$new_ptr] = $new_len;
			}
			
			$this->update();
		}
		
		function remove_segment($ptr) {
			//unset($this->end[$ptr + $this->start[$ptr]]);
			unset($this->start[$ptr]);
			$this->update();
		}
		
		function add_segment($ptr, $len) {
			//if (isset($this->start[$ptr])) {
			$this->start[$ptr] = @max($this->start[$ptr], $len);
			//$this->end[$ptr + $len] = $ptr;
			$this->update();
		}
		
		static function intersect($al, $ar, $bl, $br) {
			if ($al >= $br) return false;
			if ($bl >= $ar) return false;
			if ($ar < $bl) return false;
			if ($br < $al) return false;
			return true;
		}
		
		function update() {
			ksort($this->start);
			//ksort($this->end);
			while (true) {
				$ptrs = array_keys($this->start);
				for ($n = 0; $n < sizeof($ptrs) - 1; $n++) { 
					$cptr = $ptrs[$n + 0]; $clen = $this->start[$cptr];
					$nptr = $ptrs[$n + 1]; $nlen = $this->start[$nptr];
					if (self::intersect($cptr, $cptr + $clen, $nptr, $nptr + $nlen)) {
						$dest = max($cptr + $clen, $nptr + $nlen);
						$this->remove_segment($nptr);
						//$this->remove_segment($cptr);
						$this->change_segment($cptr, $dest - $cptr);
						//echo "Merged! : $cptr-$clen U $nptr-$nlen\n";
						continue 2;
					}
				}
				break;
			}
		}
		
		function add($ptr, $len) {
			//printf("ADD: %08X:%d\n", $ptr, $len);
			$this->add_segment($ptr, $len);
		}
		
		function get($len) {
			$min = 0x7FFFF;
			$found = false;
			foreach ($this->start as $ptr => $clen) {
				if ($clen >= $len && $clen < $min) {
					$min = $clen;
					$found = array($ptr, $clen);
				}
			}
			
			if ($found !== false) {
				list($ptr, $clen) = $found;
				$this->change_segment($ptr, $clen - $len, $ptr + $len);
				return $ptr;
			}
			
			throw(new Exception("Can't get a segment with length {$len}"));
		}
	}
	
	class LOCATE {
		public $area;
		public $texts = array();
		
		function __construct() {
			$this->area = new AREA();
		}
		
		function put($text, $repeat = true) {
			if ($repeat && isset($this->texts[$text])) return $this->texts[$text];
			return $this->texts[$text] = $this->area->get(strlen($text));
		}
	}
	
	class FILE_LOCATE extends LOCATE {
		private $file, $base, $data;
		
		function __construct($file, $base) {
			$this->file = $file;
			$this->base = $base;
			$this->data = file_get_contents($file);
			//$this->f = fopen('');
			parent::__construct();
		}
		
		function __destruct() {
			file_put_contents($this->file, $this->data);
		}
		
		function put($text, $repeat = true) {
			$r = parent::put($text, $repeat);
			//print_r($this->area);
			//echo "$text -> $r\n";
			return $r;
		}
		
		static function getString($t) {
			if (substr($t, 0, 1) != "'" || substr($t, -1, 1) != "'") throw(new Exception("Invalid line"));
			$tt = substr($t, 1, -1);
			return iconv('ISO-8859-15', 'CP857', $tt) . "\0";
		}

		public $t_texts = array(), $t_ptrs = array();
		
		function write($pos, $str) {
			if (!strlen($str)) break;
			if ($pos + strlen($str) >= strlen($this->data)) throw(new Exception(sprintf("Writting out of bounds (0x%08X | 0x%08X) : '%s'", $pos, strlen($this->data), $str)));
			$this->data = substr_replace($this->data, $str, $pos, strlen($str));
		}
		function read($pos, $len) { return substr($this->data, $pos, $len); }
		function search($text) {
			//echo strlen($this->data) . '/' . $this->base . "\n";
			$r = strpos($this->data, $text, $this->base);
			if ($r !== false) $r -= $this->base;
			return $r;
		}
	
		function process($file) {
			echo "Processing...'{$file}'\n";
			$texts = &$this->t_texts;
			$ptrs = &$this->t_ptrs;
			
			foreach (file($file) as $ln => $l) { $ln++;
				try {
					list($l) = explode('//', $l); $l = trim($l);
					if (!strlen($l)) continue;
					@list($type, $v1, $v2) = explode(':', $l, 3);
					@list($type, $v1, $v2) = array(strtoupper(trim($type)), trim($v1), trim($v2));
					switch ($type) {
						default: throw(new Exception("Invalid type: '{$type}'"));
						case 'RANGE':
							$this->area->add((int)hexdec($v1), (int)$v2);
						break;
						case 'PTR16':
							list($t1, $t2) = explode('||', $v2);
							foreach (explode(',', $v1) as $v1) {
								$v1 = (int)hexdec(trim($v1));
								
								$len = strlen($t1s = self::getString($t1));
								
								list(,$bptr) = unpack('v', $this->read($v1, 2));
								
								//printf("PTR16:0x%08X 0x%08X\n", $v1, $bptr);
								
								$this->area->add($bptr, $len);
								$text = self::getString($t2);
								if ($v1 < 0x200) throw(new Exception('Invalid address'));
								$texts[$text][] = array($type, $v1);
								
								if (isset($ptrs[$v1])) throw(new Exception("Repeated pointer"));
								$ptrs[$v1] = true;
							}
						break;
					}
				} catch (Exception $e) {
					echo "ERROR: " . $e->getMessage() . " en la línea {$ln}";
					exit;
				}
				//print_r($this->area->start);
			}
		}
		
		function perform() {
			$texts = &$this->t_texts;
			$ptrs = &$this->t_ptrs;
			
			//print_r($this->area->start);
		
			foreach ($this->area->start as $k => $v) $this->write($k + $this->base, str_repeat("\0", $v));
			
			uksort($texts, array('FILE_LOCATE', 'csort'));

			$errors = array();
			//print_r(array_keys($texts));
			foreach ($texts as $text => $params_a) {
				try {
					$ptr = $this->search($text);
					$write = false;
					if ($ptr === false) {
						$ptr = $this->put($text);
						$write = true;
					}
					foreach ($params_a as $params) {
						switch ($params[0]) {
							default: throw(new Exception("Invalid type II: '{$type}'"));
							case 'PTR16':
								//echo $params[1] . "\n";
								$this->write($params[1], pack('v', $ptr));
								if ($write) {
									$this->write($this->base + $ptr, $text);
								}
								//printf("%08X:%08X:'%s'\n", $params[1], $this->base + $ptr, $text);
							break;
						}
					}
				} catch (Exception $e) {
					$errors[] = array($text, $e);
				}
			}
			
			if (sizeof($errors)) {
				print_r($this->area->start);
				foreach ($errors as $error) {
					list($text, $e) = $error;
					echo "ERROR('{$text}'): " . $e->getMessage() . "\n";
				}
				exit;
			}
		
		}
		
		function csort($a, $b) {
			$a = strlen($a); $b = strlen($b);
			return ($a < $b) ? 1 : (($a > $b) ? -1 : 0);
		}
	}
	
	class VOL {
		public $start = 0;
		public $files = array();
		
		function __construct($file = null, $max = 0xFFFF) {
			if (!isset($file)) return;
			$pv = array();
			foreach (unpack('V*', substr($file, 0, $max * 4)) as $p) {
				if ($p == 0) break;
				$pv[] = $p;
			}
			$this->start = $pv[0];
			$this->files = array();
			for ($n = 0; $n < sizeof($pv) - 1; $n++) {
				$pos = $pv[$n];
				$len = $pv[$n + 1] - $pos;
				$this->files[$n] = substr($file, $pos, $len);
			}
		}
		
		function add($data) {
			$this->files[] = $data;
		}
		
		function finish() {
		}
		
		function get() {
			$start = &$this->start;
			$msize = (sizeof($this->files) + 1) * 4;
			$head = ''; if ($start < $msize) $start = $msize;
			$pos = $start; $count = sizeof($this->files);
			for ($n = 0; $n <= $count; $n++) {
				$head .= pack('V', $pos);
				if ($n < $count) $pos += strlen($this->files[$n]);
			}
		
			return str_pad($head, $this->start, "\0", STR_PAD_RIGHT) . implode('', $this->files);
		}
		
		static function decode($s) {
			$r = '';
			for ($n = 0, $l = strlen($s); $n < $l; $n++) {
				$c = ord($s{$n});
				if ($c >= 0x20) $c = ~$c + 0x20;
				$r .= chr($c);
			}
			return iconv('CP857', 'ISO-8859-15', $r);
		}

		static function encode($s) {
			$r = ''; $s = iconv('ISO-8859-15', 'CP857', $s);
			for ($n = 0, $l = strlen($s); $n < $l; $n++) {
				$c = ord($s{$n});
				if ($c >= 0x20) $c = ~($c - 0x20);
				$r .= chr($c);
			}
			return $r;
		}
	}
	
	function extract_items_desc($file) {
		$ptrs = array_values(unpack('v*', substr($file, 0, 0x130)));
		$texts = array();
		foreach ($ptrs as $k => $ptr) {
			list($s) = explode("\0", substr($file, $ptr), 2);
			$s = addcslashes($s, "\n\r");
			$texts[$s][] = $k;
		}
		$f_idxs = $f_texts = array();
		foreach ($texts as $text => $idxs) {
			$f_texts[] = iconv('CP857', 'ISO-8859-15', $text);
			$f_idxs[] = implode(',', $idxs);
		}
		
		file_put_contents('txt/dat/items_desc.en.txt', implode("\n", $f_texts));
		file_put_contents('txt/dat/items_desc.idx', implode("\n", $f_idxs));

		$head = array();
		$data = '';
		$start = 0x130;
		foreach (file('txt/dat/items_desc.es.txt') as $k => $line) {
			if ($k >= 0x130 / 2) break;
			$line = iconv('ISO-8859-15', 'CP857', stripcslashes(trim($line))) . "\0";
			$pos = strlen($data) + $start;
			$data .= $line;
			foreach (explode(',', $f_idxs[$k]) as $idx) $head[$idx] = pack('v', $pos);
		}
		ksort($head);
		
		return implode('', $head) . $data;
	}
	
	function process_dat_file() {
		echo "Procesando DAT.VOL...";
		if (true) {
			if (!file_exists('DAT.VOL.BAK')) copy('DAT.VOL', 'DAT.VOL.BAK');
			$vol = new VOL(file_get_contents('DAT.VOL.BAK'));
			
			$vol->files[23] = extract_items_desc($vol->files[23]);
			
			file_put_contents('DAT.VOL', $vol->get());
		}
		echo "Ok\n";
	}

	function process_med_file() {
		echo "Procesando MED.VOL...";
		if (true) {
			if (!file_exists('MED.VOL.BAK')) copy('MED.VOL', 'MED.VOL.BAK');
			$vol = new VOL(file_get_contents('MED.VOL.BAK'));

			$texts_t = file('txt/dat/maps.es.txt');
			$texts = array();
			foreach ($vol->files as &$file) {
				list($name) = explode("\0", substr($file, 0x40, 0x20), 2);
				$texts[] = $name;
				
				if (sizeof($texts_t)) $name = trim(array_shift($texts_t));
				
				//echo "$name\n";
				
				$file = substr_replace($file, str_pad($name, 0x20, "\0", STR_PAD_RIGHT), 0x40, 0x20);
			}
			
			file_put_contents('txt/dat/maps.en.txt', implode("\n", $texts));
			
			file_put_contents('MED.VOL', $vol->get());
		}
		echo "Ok\n";
	}
	
	function process_code_file() {
		echo "Procesando CODE.VOL...";
		if (true) {	
			if (!file_exists('CODE.VOL.BAK')) copy('CODE.VOL', 'CODE.VOL.BAK');
			$vol = new VOL(file_get_contents('CODE.VOL.BAK'));	
			
			foreach ($vol->files as $k => &$file) {
				$en = sprintf('txt/script/en.%02d.txt', $k);
				$es = sprintf('txt/script/es.%02d.txt', $k);
				file_put_contents($en, VOL::decode($file));
				if (file_exists($es)) $file = VOL::encode(file_get_contents($es));
			}
			
			file_put_contents('CODE.VOL', $vol->get());
		}
		echo "Ok\n";
	}
	
	function process_exe() {
		echo "Procesando CM.EXE...";
		if (true) {
			if (!file_exists('CM.EXE.BAK')) copy('CM.EXE', 'CM.EXE.BAK');
			copy('CM.EXE.BAK', 'CM.EXE');
			$locate = new FILE_LOCATE('CM.EXE', 0x15E10);
			foreach (scandir($path = 'txt/exe') as $f) { $rf = "{$path}/{$f}";
				if (!is_file($rf)) continue;
				if (substr($f, 0, 1) == '.') continue;
				$locate->process($rf);
				//if ($n++ >= 3) { print_r($locate->area); exit; }
			}
			//exit;
			$locate->perform();
		}
		echo "Ok\n";
	}
	
	process_exe();
	process_dat_file();
	process_med_file();
	process_code_file();
?>