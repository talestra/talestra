<?php
	function find_text() {
		$ret = array();
		$start = false;
		$startp = 0;
		
		$base = 0x15E10;
		
		$exe = file_get_contents('CM.EXE.BAK', 0, null, $base);
		for ($n = 0, $l = strlen($exe); $n < $l; $n++) {
			$c = ord($exe{$n});
			if ($c >= 0x20 && $c <= 0x7F) {
				if (!$start) {
					$startp = $n;
					$start = true;
				}
				continue;
			} else if ($c == 0) {
				if ($start) {
					$len = $n - $startp;
					if ($len >= 2) {
						//$ret[$startp + $base] = array(substr($exe, $startp, $len), $len, array());
						$ret[$startp] = array(substr($exe, $startp, $len), $len, array());
					}
				}
				$start = false;
			} else {
				$start = false;
			}
		}
		return $ret;
	}
	
	$texts = find_text();
	
	//foreach ($texts as $k => $t) printf("%s\n", $t[0]); exit;
	
	unset($texts[4]);
	
	$base = 0x15E10;
	$exe = array_values(unpack('v*', file_get_contents('CM.EXE.BAK', 0, null, $base)));
	$just = false;
	foreach ($exe as $k => $v) {
		if (isset($texts[$v])) {
			printf("PTR16:%08X:'%s'||'%s'", $base + $k * 2, $texts[$v][0], $texts[$v][0]);
			if ($v <= $k * 2) printf(" // ERROR\n");
			printf("\n");
			$just = true;
			//echo 'aaaa';
		} else {
			if ($just) {
				echo "-------------\n";
			}
			$just = false;
		}
	}
	exit;
	
	// DATA SEGMENT (in the bushes): 0x15E10
	
	$a = array(
		'Nothing',
		'Steel Pipe',
		'Pocket Knife',
		'Baseball Bat',
		'Metallic Bat',
		'Bull Whip',
		'Dagger',
		'Bamboo Cutter',
		'Steel Rod',
		'Ax',
		'Ancient Sword',
	);
	$search = array(); for ($n = 0; $n < sizeof($a) - 1; $n++) $search[] = strlen($a[$n]) + 1;
	
	$v = unpack('v*', file_get_contents('CM.EXE'));
	//print_r($v);
	for ($n = 1; $n <= sizeof($v); $n++) {
		$back = $v[$n];
		$find = false;
		for ($m = 1; $m < sizeof($search); $m++, $back = $cur) { $cur = @$v[$n + $m];
			$find = true;
			if ($cur - $back != $search[$m - 1]) {
				$find = false;
				break;
			}
		}
		if ($find) {
			printf("%08X\n", ($n - 1) * 2);
		}
	}
?>