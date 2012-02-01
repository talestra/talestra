<?php
function fread4($f) { list(,$v) = unpack('V', fread($f, 4)); return $v; }
if (!file_exists('data_t.jp.pac')) copy('data_t.pac', 'data_t.jp.pac');
$f = fopen('data_t.jp.pac', 'rb');
$count = fread4($f);
$tsize = fread4($f);
$list = array();
for ($n = 0; $n < $count; $n++) {
	$size   = fread4($f);
	$offset = fread4($f);
	$name_data = fread($f, 0x200);
	list($name)   = explode("\0", mb_convert_encoding($name_data, 'utf-8', 'UTF-16LE'), 2);
	$list[] = array($name, $offset, $size);
}

foreach ($list as $file) {
	list($name, $offset, $size) = $file;
	@mkdir(dirname($name), 0777);
	fseek($f, $offset);
	file_put_contents($name, fread($f, $size));
}