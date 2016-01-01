<?php
	require_once(dirname(__FILE__) . '/common.php');
	
	function extract_text_callback($file, $rfile, $pname) {
		echo "Extracting: {$file}...";
		$msg = MsgFile::fromFile($rfile);
		$msg->exportPointers("scr/{$pname}");
		echo "Ok\n";	
	}
	
	process_dir('extract_text_callback', 'ISO/CD');
?>