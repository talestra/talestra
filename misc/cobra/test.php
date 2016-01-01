<?php
	$d = file_Get_contents('ICP.VOL');
	for ($n = 0, $l = strlen($d); $n < $l; $n++) {
		$c = ord($d{$n});
		if ($c >= 0x20) {
			$d{$n} = chr(~$c + 0x20);
		}
	}
	file_put_contents('bbbb.DAT', $d);
?>