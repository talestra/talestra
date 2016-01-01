function $(id) {
	if (id.substr(0, 1) == '#') return document.getElementById(id.substr(1));
	return document.getElementById(id);
}

function portableAttachEvent(nevent, callback) {
	(document.all) ?
		window.attachEvent('on' + nevent, callback) :
		window.addEventListener(nevent, callback, true)
	;
}

var Debug = { lines : [] };

Debug.serialize = function(s) {
	if (s instanceof Object) {
		//$('zout').innerHTML = 'lol' + '<br />' + $('zout').innerHTML;
		var ss = '', n = 0;
		for (key in s) {
			if (n != 0)	ss += ', '
			ss += key + ': ' + Debug.serialize(s[key]);
			n++;
		}
		return ss;
	}

	return s;
};

Debug.trace = function(s) {
	//$('zout').innerHTML = Debug.serialize(s) + '<br />' + $('zout').innerHTML;
	$('zout').innerHTML = Debug.serialize(s) + '<br />' + $('zout').innerHTML.substr(0, 800);
};

var Background = {};

Background.set = function(image, w, h) {
	Debug.trace('Cargando fondo: ' + image);
	$('content').style.backgroundImage = "url('" + image + "')";
	camera.width = w;
	camera.height = h;
};

Background.addLine = function(x1, y1, x2, y2) {
	geometry.lines[geometry.lines.length] = { 'x1' : x1, 'y1' : y1, 'x2' : x2, 'y2': y2 };
};

var overlays = [];

Background.addOver = function(image, x, y, w, h, z) {
	if (z === undefined) z = height;
	var newoverlayer = document.createElement('div');
	with (newoverlayer.style) {
		left    = x + 'px';
		top     = y + 'px';
		width   = w + 'px';
		height  = h + 'px';
		zIndex  = y + z;
		position = 'absolute';
		visibility = 'hidden';
		backgroundImage = "url('" + image + "')";
	}
	Debug.trace('Cargando overlay: ' + image);
	$('content').appendChild(newoverlayer);
	
	newoverlayer.px = x;
	newoverlayer.py = y;
	
	overlays[overlays.length] = newoverlayer;
};

Background.update = function() {
	updateLines();
};

var Map = {};

Map.load = function(file) {
	Debug.trace('Cargando mapa: ' + file);
	
	var mapscript = document.createElement('script');
	mapscript.src = 'images/' + file + '.js';
	mapscript.language = 'JavaScript';
	$('content').appendChild(mapscript);

	var mapscript = document.createElement('script');
	mapscript.src = 'images/' + file + '_lines' + '.js';
	mapscript.language = 'JavaScript';
	$('content').appendChild(mapscript);
};
