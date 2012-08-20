<?php
	class Assembler {
		public $data;
		public $PC;
		public $symbols;
		public $relocs;

		static public $global_symbols = array(
			// Commands
			'NEXT'     => 0x01, // Press a button
			'B_TATE'   => 0x03,
			'SINARIO'  => 0x04,
			'BGM'      => 0x06, // Background Music
			'PAUSE'    => 0x08,
			'BUF'      => 0x13,
			'FLASH'    => 0x16,
			'GATA'     => 0x18,
			
			// Extra
			'CR'       => 0x0A, // \n
			'B_COPY01' => 0x0F,
			'C_BLD'    => 0x12,
			'G_FLG'    => 0x0C,
			'G_COPYI'  => 0x03,
			'ERASE'    => 0x14,
			'E_GFLG'   => 0x01,

			'C_V_ON'   => 0x01,
			'C_V_OFF'  => 0x02,
			'C_N_ON'   => 0x04,
			'C_N_OFF'  => 0x05,
			
			'FLG'      => 0x0B,
			'F_COPYI'  => 0x05,
			
			'B_YOKO'   => 0x39,
			'B_NORM'   => 0x32,
		);

		static function tokenize($s) {
			$r = array();
			$l = strlen($s);
			$cur = '';
			for ($n2 = $n = 0; $n < $l; $n++) {
				switch ($c = $s[$n]) {
					case '"': // string
						for ($n2 = $n++; $n < $l; $n++) {
							$c = $s[$n]; 
							if ($c == '"') break;
						}
						$r[] = substr($s, $n2, $n - $n2 + 1);
					break;
					case ':': // end label
						$r[] = ":$cur"; $cur = '';
					break;
					case ';': // comment
						break 2;
					break;
					case ',': // separator2
					case ' ': case "\t": case "\r": case "\n": // Separator
						if (strlen($cur)) { $r[] = $cur; $cur = ''; }
					break;
					default:
						$cur .= $c;
					break;
				}
			}
			if (strlen($cur)) { $r[] = $cur; $cur = ''; }
			return $r;
		}
		
		static function getval($value) {
			if (preg_match('/^[0-9A-F]+H$/i', $value)) $value = base_convert(substr($value, 0, -1), 16, 10);
			if ($value[0] == '"') return stripslashes(substr($value, 1, -1));
			if (is_numeric($value)) return (int)$value;
			return false;
		}
		
		function valuen($count, $value) {
			if (preg_match('/^[0-9A-F]+H$/i', $value)) {
				$value = base_convert(substr($value, 0, -1), 16, 10);
			}
			if (is_numeric($value)) {
				$info = pack('v', $value);
				$this->data[$this->PC++] = $info[0];
				if ($count >= 2) $this->data[$this->PC++] = $info[1];
			} else if ($value[0] == '"') {
				if ($count == 2) {
					echo "Invalid!\n";
					continue;
				}
				$info = stripslashes(substr($value, 1, -1));
				for ($n = 0, $l = strlen($info); $n < $l; $n++) $this->data[$this->PC++] = $info[$n];
			} else {
				$this->relocs[$this->PC] = array($count, $value);
				for ($n = 0; $n < $count; $n++) $this->data[$this->PC++] = "\0";
			}
		}
		
		function value1($v) { return $this->valuen(1, $v); }
		function value2($v) { return $this->valuen(2, $v); }
		
		function extract($count, $toks) {
			foreach ($toks as $value) $this->valuen($count, $value);
		}
		
		function push1($v) {
			$this->data[$this->PC++] = chr($v);
		}
		
		function label($label) {
			$this->symbols[$label] = $this->PC;
		}

		function assemble($lines) {
			$this->PC = 0;
			$this->symbols = self::$global_symbols;
			$this->relocs = array();
			$this->data = '';
			foreach ($lines as $line) {
				if (!count($toks = self::tokenize(trim($line)))) continue;
				// This line has a label.
				if ($toks[0][0] == ':') {
					$this->label(substr(array_shift($toks), 1));
					if (!count($toks)) continue;
				}
				switch ($OP = strtoupper($toks[0])) {
					case 'INCLUDE': // ignore
						$file = strtoupper(($toks[1][0] == '"') ? stripslashes(substr($toks[1], 1, -1)) : $toks[1]);
						switch ($file) {
							case 'SUPER_S.INC': // Macros?
							break;
							case 'N_NAME00.INC': $this->label('N_FNAME'); $this->value1(0x00); break;
							case 'V_NAME00.INC': $this->label('V_FNAME'); $this->value1(0x00); break;
							default:
								printf("Can't open '%s'\n", $file);
							break;
						}
					break;
					case 'DB': $this->extract(1, array_slice($toks, 1)); break;
					case 'DW': $this->extract(2, array_slice($toks, 1)); break;
					case 'B_O':
						$this->push1(0x15);
						$this->push1(0x04);
						
						$this->push1(0x14);
						$this->value1($toks[1]);
						$this->push1(0x3A);
					break;
					case 'BAK_INIT':
						$this->push1(0x13);
						$this->push1(0x04);
						$this->push1(0x07); // Length?
						$this->push1(0x0A);
						$this->value1($toks[1]);
						$this->push1(0x00);
					break;
					case 'B_P1': // 15 04 13 02 05 07 0A 0E 3C 04 00 (B_SUDA)
						$this->push1(0x15);
						$this->push1(0x04);

						$this->push1(0x13);
						$this->push1(0x02);
						$this->push1(0x05);
						$this->push1(0x07);
						$this->push1(0x0A);
						$this->push1(0x0E);
						$this->push1(0x3C);
						$this->push1(0x04);
						$this->push1(0x00);
					break;
					case 'T_CG1':
					case 'T_CG': // 15 04 | 13 03 08 09 0D 0A 00 [43 54 31 30 00] 13 02 05 07 0A 0E 3C 03 00 15 01 01 0D 0A 00 [43 54 31 30 41 30 00] (T_CG "CT10",0,0,10,1)
						$prefix1 = '';
						$prefix2 = '';
						if (self::getval($toks[2]) !== 0) $prefix1 = self::getval($toks[2]);
						if (self::getval($toks[3]) !== 0) $prefix2 = self::getval($toks[3]);
						$x = self::getval($toks[4]);
						$y = self::getval($toks[5]);

						$this->push1(0x15);
						$this->push1(0x04);

						$this->push1(0x13);
						$this->push1(0x03);
						$this->push1(0x08);
						$this->push1(0x09);
						
						$this->push1(0x0D);
						$this->push1($x);
						$this->push1(0x00);
						$this->value1('"'. self::getval($toks[1]) . $prefix1 . '"'); $this->push1(0x00);

						if ($prefix2 != '') {
							$this->push1(0x13);
							$this->push1(0x03);
							$this->push1(0x08);
							$this->push1(0x09);
							$this->push1(0x0D);
							$this->push1(0x0C);
							$this->push1(0x00);
							$this->value1('"'. self::getval($toks[1]) . $prefix2 . '"'); $this->push1(0x00);
						}

						$this->push1(0x13);
						$this->push1(0x02);
						$this->push1(0x05);
						$this->push1(0x07);
						$this->push1(0x0A);
						$this->push1(0x0E);
						$this->push1(0x3C);
						$this->push1(0x03);
						$this->push1(0x00);

						$this->push1(0x15);
						$this->push1(0x01);
						$this->push1($y);
						
						$this->push1(0x0D);
						$this->push1($x);
						$this->push1(0x00);
						$this->value1('"'. self::getval($toks[1]) . $prefix2 . 'A0' . '"'); $this->push1(0x00);
					break;
					case 'E_CG': // 15 04 13 01 05 07 0A 0E [39 54 5F 30 31 00] (E_CG B_YOKO,"T_01")
						// B_NORM 0x32
						// B_YOKO 0x39
						$this->push1(0x15);
						$this->push1(0x04);
						
						$this->push1(0x13);
						$this->push1(0x01);
						$this->push1(0x05);
						$this->push1(0x07);
						$this->push1(0x0A);
						$this->push1(0x0E);
						//$this->push1(0x39);
						$this->value1($toks[1]);
						$this->value1($toks[2]);
						$this->push1(0x00);
					break;
					case 'END':
					break 2;
					default:
						printf("Unknown TOK '%s'\n", $toks[0]);
						print_r($toks);
					break;
				}
				//printf("%s\n", $toks[0]);
			}
			foreach ($this->relocs as $CPC => $reloc) {
				if (!isset($this->symbols[$reloc[1]])) {
					printf("Unknown symbol '%s'\n", $reloc[1]);
					$this->symbols[$reloc[1]] = 0x7777;
				}
				//printf("%08X : %s\n", $CPC, $reloc[1]);
				switch ($reloc[0]) {
					case 1:
						$info = pack('c', $this->symbols[$reloc[1]]);
						$this->data[$CPC++] = $info[0];
					break;
					case 2:
						$info = pack('v', $this->symbols[$reloc[1]]);
						$this->data[$CPC++] = $info[0];
						$this->data[$CPC++] = $info[1];
					break;
				}
			}
			file_put_contents("temp", $this->data);
			//print_r($labels);
		}
		
		function assemble_file($file) {
			printf("Processing '%s'...\n", $file);
			$this->assemble(file($file));
		}
	}
	$asm = new Assembler();
	$asm->assemble_file('data/data/cs104.asm');
?>