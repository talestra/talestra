<?php
	function fread32($f) { return ($r = unpack('V', fread($f, 4))) ? $r[1] : false; }

	if (!($f = fopen('fftpack.bin', 'rb')))  die('No se encuentra ffpack.bin');
		
	$count = fread32($f); // COUNT
	$pposs = fread32($f); // TABLE (positions)
	$psize = fread32($f); // TABLE (sizes)
	$start = fread32($f); // START
	
	fseek($f, $pposs);
	$tposs = fread($f, $count * 4);

	fseek($f, $psize);
	$tsize = fread($f, $count * 4);
	
	@mkdir('BIN', 0777);
	
	for ($n = 0; $n < $count; $n++) {
		list(,$cposs) = unpack('V', substr($tposs, $n * 4, 4));
		list(,$csize) = unpack('V', substr($tsize, $n * 4, 4));
		
		fseek($f, $cposs);
		@file_put_contents($fn = sprintf('BIN/%04d.bin', $n), fread($f, $csize));
		printf("%s : %08X(%08X)\n", $fn, $cposs, $csize);
	}
	
	fclose($f);
?>