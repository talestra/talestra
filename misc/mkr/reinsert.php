<?php
	require_once(dirname(__FILE__) . '/common.php');
	
	function extract_text_callback($file, $rfile, $pname) {
		echo "Reinserting: {$file}...";
		$msg = MsgFile::fromFile($rfile);
		$msg->importPointers("scr/{$pname}");
		$msg->save($rfile);
		echo "Ok\n";	
	}
	
	process_dir('extract_text_callback', 'ISO/CD');
?>