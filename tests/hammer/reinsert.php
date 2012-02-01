<?php
function fread4($f) { list(,$v) = unpack('V', fread($f, 4)); return $v; }

function getlist() {
	$f = fopen('data_t.jp.pac', 'rb');
	$count = fread4($f);
	$tsize = fread4($f);
	$list = array();
	for ($n = 0; $n < $count; $n++) {
		$size   = fread4($f);
		$offset = fread4($f);
		$name_data = fread($f, 0x200);
		list($name)   = explode("\0", mb_convert_encoding($name_data, 'utf-8', 'UTF-16LE'), 2);
		$list[] = $name;
	}
	return $list;

}

if (!file_exists('data_t.jp.pac')) copy('data_t.pac', 'data_t.jp.pac');

$count = 0;
$list = array();
$pos = 0;
//foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator('data')) as $filename => $cur) {
foreach (getlist() as $filename) {
	if (preg_match('/(keyRec|sound)/', $filename)) continue;
	$filename = str_replace('\\', '/', $filename);
	$size = filesize($filename);
	$list[] = array($filename, $pos, $size);
	$pos += $size;
	$count++;
	//echo "$filename\n";
}
$data_size = $pos;

$f = fopen('data_t.pac', 'wb');
$header_size = 4 + 4 + (4 + 4 + 0x200) * $count;
fwrite($f, pack('VV', $count, $header_size + $data_size));

foreach ($list as $n => $file) {
	list($filename, $filepos, $filesize) = $file;
	fwrite($f, pack('VV', $filesize, $header_size + $filepos));
	fwrite($f, str_pad(mb_convert_encoding($filename, 'UTF-16LE', 'utf-8'), 0x200, "\0"));
}

foreach ($list as $n => $file) {
	list($filename, $filepos, $filesize) = $file;
	echo "{$filename}\n";
	assert('ftell($f)==($header_size + $filepos)');
	//fseek($f, $header_size + $filepos);
	fwrite($f, file_get_contents($filename));
}