var Geometry = function() {
	this.lines = [];
	this.rects = {};
};

Geometry.collisionLineRectangle = function(l, r) {
	var p = { x : l.x2 - l.x1, y : l.y2 - l.y1}

	function compareSign(a, b) { return (a == b) || (a == 0) || (b == 0); }
	function relativePoint(a, b) { return Math.sign((a.x * b.y) - (b.x * a.y)); };
	function normalizeRect(r) { return { 'x1' : Math.min(r.x1, r.x2), 'y1' : Math.min(r.y1, r.y2), 'x2' : Math.max(r.x1, r.x2), 'y2' : Math.max(r.y1, r.y2)}; };

	if (!Geometry.checkCollisionRect2(normalizeRect(l), r)) return false;

	var sign1 = 0, sign2;
	if (!compareSign(sign1, sign2 = relativePoint(p, {x: r.x1 - l.x1, y: r.y1 - l.y1}))) return true;
	if (!compareSign(sign2, sign1 = relativePoint(p, {x: r.x2 - l.x1, y: r.y1 - l.y1}))) return true;
	if (!compareSign(sign1, sign2 = relativePoint(p, {x: r.x1 - l.x1, y: r.y2 - l.y1}))) return true;
	if (!compareSign(sign2, sign1 = relativePoint(p, {x: r.x2 - l.x1, y: r.y2 - l.y1}))) return true;

	return false;
};

// Comprobamos si colisionan dos rectángulos entre sí
Geometry.checkCollisionRect2 = function(r1, r2) {
	return (r1.x1 <= r2.x2) && (r1.x2 >= r2.x1) && (r1.y1 <= r2.y2) && (r1.y2 >= r2.y1);
};

Geometry.getDisplacedRect = function(r, d) { return { 'x1' : r.x1 + d.x, 'x2' : r.x2 + d.x, 'y1' : r.y1 + d.y, 'y2' : r.y2 + d.y }; }

Geometry.prototype.checkLinesCollision = function(rect) {
	var list = [];

	for (var n = 0; n < this.lines.length; n++) {
		if (Geometry.collisionLineRectangle(this.lines[n], rect)) list[list.length] = this.lines[n];
	}

	return list;
};

Geometry.prototype.checkRectsCollision = function(rect, unrect) {
	var list = [];

	function compareRect(r1, r2) {
		if (!r1 || !r2) return true;
		return (r1.x1 == r2.x1) && (r1.y1 == r2.y1) && (r1.x2 == r2.x2) && (r1.y2 == r2.y2);
	}

	for (key in this.rects) {
		if (compareRect(this.rects[key], unrect)) continue;
		if (Geometry.checkCollisionRect2(this.rects[key], rect)) list[list.length] = this.rects[key];
	}

	return list;
};

// Comprobamos si un rectángulo colisiona con las geometrías establecidas
Geometry.prototype.checkCollision = function(rect, d) {
	// Obtenemos el rectángulo desplazado la cantidad especificada
	var nrect = Geometry.getDisplacedRect(rect, d);

	var clines = this.checkLinesCollision(nrect);
	var crects = this.checkRectsCollision(nrect, rect);	
	
	// No hay ningún tipo de colisión
	if (clines.length == 0 && crects.length == 0) {
		return d;
	}
	
	Debug.trace('Colisiones: [lines:' + clines.length + ', rects:' + crects.length + ']');

	// Colisiones entre líneas
	for (var n = 0; n < clines.length; n++) {
		var line = clines[n];
		var vd = { 'x' : (line.x2 - line.x1), 'y' : (line.y2 - line.y1) };
		var vdl = Math.pol(vd.x, vd.y); vd.x /= vdl; vd.y /= vdl;
		var vecp = (vd.x * d.x + vd.y * d.y);
		var nd = { 'x' : vecp * vd.x, 'y' : vecp * vd.y };
		var nrect2 = Geometry.getDisplacedRect(rect, nd);

		if (!this.checkLinesCollision(nrect2).length && !this.checkRectsCollision(nrect2, rect).length) {
			return nd;
		}
	}

	// Colisiones con rectángulos
	{
		var nd = { 'x' : 0, 'y' : d.y };
		var nrect2 = Geometry.getDisplacedRect(rect, nd);
		if (this.checkLinesCollision(nrect2).length == 0 && this.checkRectsCollision(nrect2, rect).length == 0) {
			return nd;
		}
	
		var nd = { 'x' : d.x, 'y' : 0 };
		var nrect2 = Geometry.getDisplacedRect(rect, nd);
		if (this.checkLinesCollision(nrect2).length == 0 && this.checkRectsCollision(nrect2, rect).length == 0) {
			return nd;
		}
	}

	// Estamos chocando contra varias geometrías
	// Comprobamos si actualmente también estamos chocando para poder salir del bloqueo
	if (this.checkLinesCollision(rect).length || this.checkRectsCollision(rect, rect).length) {
		// Estabamos chocando también antes. Es un caso no deseado, pero deberíamos poder salir de ahí.
		return d;
	}

	return false;
};