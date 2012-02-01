<?php
	function fread32 ($f)    { return ($r = unpack('V', fread($f, 4))) ? $r[1] : false; }
	function fwrite32($f, $v) { fwrite($f, pack('V', $v)); }
	function align_next($pos, $align = 0x800) {
		if (($mod = $pos % $align) == 0) return $pos;
		return $pos + ($align - $mod);
	}
	
	function falign($f, $align = 0x800) {
		return align_next(ftell($f), $align);
	}

	if (!($f = fopen('fftpack.mod.bin', 'wb'))) die('No se pudo escribir el ffpack.mod.bin');
	
	$count = 3968;
	//$count = 3;
	$pposs = 0x10;
	$psize = $pposs + $count * 4;
	$start = align_next($psize + $count * 4);
	
	fwrite32($f, $count);
	fwrite32($f, $pposs);
	fwrite32($f, $psize);
	fwrite32($f, $start);
	
	$cpos = $start;
	
	for ($n = 0; $n < $count; $n++) {
		$cf = sprintf('bin/%04d.bin', $n);
		echo "{$cf}...";
		
		fseek($f, $pposs); $pposs += 4;
		fwrite32($f, $cpos);
		
		fseek($f, $cpos);
		fwrite($f, file_get_contents($cf));
		$cpos = falign($f);

		fseek($f, $psize); $psize += 4;
		fwrite32($f, ftell($f) - $cpos);
		echo "Ok\n";
	}
	
	if (ftell($f) < $cpos - 1) {
		fseek($f, $cpos - 1);
		fwrite($f, "\0");
	}
?>