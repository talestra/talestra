var sprites = {};
var agroups = {};

function LoadAnimationGroup(id, callback) {
	// La animación ya está cargada
	if (agroups[id]) {
		if (callback) callback(id);
	}
	// La animación no se ha cargado todavía
	else {
		XmlHTTP.GetXML(id + '.xml', function(xml) {
			if (!xml) throw("No se pudo cargar la animación '" + id + "'");
			agroups[id] = ParseXMLAnimationGroup(xml, function() {
				if (callback) callback(id);
			});
		});
	}
};

function ParseXMLAnimationGroup(xml, callback) {
	var xagroup = xml.firstChild;

	if (xagroup.nodeName != 'agroup') throw("This isn't a 'agrup' document");

	var images = {};
	var cuts   = {};
	var anims  = {};
	var imagesLoaded = 0;

	function EvalIntValue(v) {
		var a; eval('a=' + v);
		return a;
	}

	// Obtenemos el listado de imágenes
	var ximages = xagroup.getElementsByTagName('image');
	for (xin = 0; xin < ximages.length; xin++) {
		var ximage   = ximages[xin];
		var image    = new Image();
		var at       = ximage.attributes;
		image.id     = at['id'].nodeValue;
		image.width  = EvalIntValue(at['width'].nodeValue);
		image.height = EvalIntValue(at['height'].nodeValue);
		image.onload = function() {
			imagesLoaded++;
			if (imagesLoaded >= ximages.length) {
				if (callback) callback();
			}
		};
		image.src    = at['file'].nodeValue;

		images[image.id] = image;
	}

	// Obtenemos el listado de cortes
	var xcuts = xagroup.getElementsByTagName('cut');
	for (xin = 0; xin < xcuts.length; xin++) {
		var xcut     = xcuts[xin];
		var cut      = {};
		var at       = xcut.attributes;
		cut.imageid  = at['imageid'].nodeValue;
		cut.image    = images[cut.imageid];
		cut.id       = at['id'].nodeValue;
		cut.x        = EvalIntValue(at['x'].nodeValue);
		cut.y        = EvalIntValue(at['y'].nodeValue);
		cut.width    = EvalIntValue(at['width'].nodeValue);
		cut.height   = EvalIntValue(at['height'].nodeValue);
		cut.cx       = EvalIntValue(at['centerx'].nodeValue);
		cut.cy       = EvalIntValue(at['centery'].nodeValue);

		cuts[cut.id] = cut;
	}

	function ParseFrame(xframe) {
		var puts = [];
		var xchilds = xframe.childNodes;
		for (var xfin = 0; xfin < xchilds.length; xfin++) {
			var xchild = xchilds[xfin];
			switch (xchild.nodeName) {
				case 'put':
					var at    = xchild.attributes;
					var cutid = at['cutid'].nodeValue;
					var x     = EvalIntValue(at['x'].nodeValue);
					var y     = EvalIntValue(at['y'].nodeValue);
					puts[puts.length] = {'x' : x, 'y' : y, 'cutid' : cutid, 'cut' : cuts[cutid]};
				break;
			}
		}
		return puts;
	};

	function ParseFrames(xframes) {
		var frames = [];
		for (var xfin = 0; xfin < xframes.length; xfin++) {
			var xframe = xframes[xfin];
			switch (xframe.nodeName) {
				case 'frame':
					frames[frames.length] = ParseFrame(xframe);
					frames[frames.length - 1].time = 1;
				break;
				case 'loop':
					throw('Sin implementar');
				break;
			}
		}
		return frames;
	};

	// Obtenemos el listado de animaciones
	var xanims = xagroup.getElementsByTagName('animation');
	for (var xin = 0; xin < xanims.length; xin++) {
		var xanim = xanims[xin];
		var animid = xanim.attributes['id'].nodeValue;

		anims[animid] = ParseFrames(xanim.childNodes);
	}

	if (!anims['default']) { for (id in anims) { anims['default'] = anims[id]; break; } }

	var n = 0; for (id in anims) n++; anims.length = n;

	return anims;
};

Sprite = function() {
	this.layers = [];
	this.py = this.px = 0;
	sprites[this.id = Sprite.nextId++] = this;

	this.label = document.createElement('div');
	with (this.label.style) {
		left = top = '0px';
		position = 'absolute';
		visibility = 'hidden';
	}
	this.label.className = 'spriteLabel';
	this.label.innerHTML = 'label';
	this.label.style.zIndex = 99999999;
	this.label.style.visibility = 'hidden';

	this.alpha = 0;

	$('content').appendChild(this.label);

	this.fadeIn();
};

Sprite.updateAll = function() {
	for (key in sprites) {
		sprites[key].updateFrame();
	}
};

Sprite.nextId = 0;

Sprite.prototype.fadeIn = function() {
	var sprite = this;
	var interval = setInterval(function() {
		sprite.alpha += 0.1;

		sprite.update = true;
		sprite.updateFrame();

		if (sprite.alpha >= 1) {
			sprite.alpha = 1;
			clearInterval(interval);
		}
	}, 40);
};

Sprite.prototype.requireLayers = function(max) {
	if (this.layers.length < max) {
		for (var n = this.layers.length; n < max; n++) {
			var layer = this.layers[n] = document.createElement('div');

			with (layer.style) {
				left = top = height = width = '0px';
				position = 'absolute';
				visibility = 'hidden';
				opacity = 1;
				backgroundRepeat = 'no-repeat';
			}

			$('content').appendChild(layer);
		}
	} else {
		for (var n = max; n < this.layers.length; n++) {
			var layer = this.layers[n];
			layer.style.visibility = 'hidden';
		}
	}
};

Sprite.prototype.getPuts = function() {
	return this.anim[this.frame];
};

Sprite.prototype.updateLabel = function() {
	this.label.innerHTML = this.agroupid + ':' + this.animid + ':' + this.frame;
	this.label.style.left = this.px + 'px';
	this.label.style.top = this.py + 'px';
	this.label.style.visibility = 'visible';
};

Sprite.prototype.updateFrame = function() {
	if ((this.camx == camera.x && this.camy == camera.y) && (!this.anim || !this.anim.length)) return;

	var puts = this.getPuts();

	if (this.frameUpdated) this.requireLayers(puts.length);
	//this.updateLabel();

	for (var n = 0; n < puts.length; n++) {
		var layer = this.layers[n];
		var put = puts[n];

		with (layer.style) {
			var zy = (parseInt(this.py) + parseInt(put.y));

			if (this.frameUpdated) {
				width  = put.cut.width  + 'px';
				height = put.cut.height + 'px';
				background = "url('" + put.cut.image.src + "')";
				backgroundPosition = -put.cut.x + 'px ' + -put.cut.y + 'px';
			}

			left   = (parseInt(this.px) + parseInt(put.x) - parseInt(put.cut.cx)) - camera.x + 'px';
			top    = (zy - parseInt(put.cut.cy)) - camera.y + 'px';

			zIndex = zy;
			visibility = 'visible';
			opacity = this.alpha;
		}
	}
	
	this.camx = camera.x;
	this.camy = camera.y;

	this.frameUpdated = false;
};

Sprite.prototype.setFrame = function(id) {
	var frameBack = this.frame;
	this.frame = (id < 0) ? (this.anim.length - 1) - (((-id) % this.anim.length) - 1) : id % this.anim.length;
	if (frameBack != this.frame) this.frameUpdated = true;
	this.updateFrame();
};

Sprite.prototype.nextFrame = function() {
	this.setFrame(this.frame + 1);
};

Sprite.prototype.setAnimationGroup = function(agroupid) {
	if (agroupid == this.agroupid) return;
	if (!agroups[agroupid]) throw("AnimationGroup '" + agroupid + "' doesn't exists");
	this.agroupid = agroupid;
	this.agroup = agroups[agroupid];
	this.setAnimation('default');
};

Sprite.prototype.setAnimation = function(animid) {
	if (animid == this.animid) return;
	if (!this.agroup[animid]) animid = 'default';
	this.anim = this.agroup[this.animid = animid];
	this.frame = -1;
	this.setFrame(0);
}

Sprite.prototype.setPosition = function(x, y) {
	this.px = x; this.py = y;
	this.updateFrame();
}

Sprite.prototype.moveTo = function(x, y) {
	this.px = x; this.py = y;
	this.updateFrame();
}

Sprite.prototype.move = function(x, y) {
	this.px += x; this.py += y;
	this.updateFrame();
}
