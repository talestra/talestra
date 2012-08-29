<?php

$file = file_get_contents(__DIR__ . '/../Port/Brave/src/brave/script/ScriptInstructions.hx');
preg_match_all('/@Opcode\\((0x\\w+),.*"(.*)"\\).*function\\s+(\\w+)\\(/Umsi', $file, $matches, PREG_SET_ORDER);
//print_r($matches);

usort($matches, function($a, $b) {
	return strcmp($a[1], $b[1]);
});
foreach ($matches as $match) {
	printf("AddOpcode(%s, \"%s\", \"%s\");\n", $match[1], $match[3], $match[2]);
	//AddOpcode(0x5E, "UNK_5E", "PP");
}