function AnimationAngle(type, angle) {
	var sang = '' + angle;
	while (sang.length < 3) sang = '0' + sang;
	return type + sang;
}

var Character = function(agroup) {
	var chara = this;
	this.sprite = new Sprite();
	this.sx = this.sy = this.dx = this.dy = 0;
	this.move = 0;
	this.angle2 = this.angle = 270;
	this.moveCallback = null;

	this.id = Character.nextId++;

	this.sprite.setAnimationGroup(agroup);
	this.sprite.setAnimation(AnimationAngle('stop', this.angle));

	this.sprite.setAnimation('stop270');

	this.boundBox = document.createElement('div');

	with (this.boundBox.style) {
		position = 'absolute';
		backgroundColor = 'red';
		width  = '26px';
		height = '14px';
		left   = '0px';
		top    = '0px';
		//visibility = 'visible';
		visibility = 'hidden';
	}

	$('content').appendChild(this.boundBox);

	this.moveTo(0, 0);

	setInterval(function() {
		if (!chara.move) return;

		if (chara.step >= chara.steps) {
			chara.move = 0;
			chara.moveTo(this.dx, this.dy);
			if (chara.moveCallback) chara.moveCallback(chara);
			chara.sprite.setAnimation(AnimationAngle('stop', chara.angle2));
			return;
		}

		/*
		var cx = chara.sx + (chara.distx * chara.step) / chara.steps;
		var cy = chara.sy + (chara.disty * chara.step) / chara.steps;

		var d = { 'x' : cx - chara.px, 'y' : cy - chara.py };
		*/

		/*
		var d = chara.direction;

		chara.lookTo(Math.angle(chara.sx, chara.dx, chara.dx, chara.sx));

		chara.sprite.setAnimation(AnimationAngle('walk', chara.angle2));
		chara.sprite.nextFrame();

		//Debug.trace(d.x + ',' + d.y);

		if (geometry.checkCollision(chara.getBoundRect(chara.px, chara.py), d)) {
			chara.moveTo(chara.px + d.x, chara.py + d.y);
			//chara.moveTo(parseInt(cx), parseInt(cy));
			chara.step++;
		} else {
			chara.move = false;
			if (chara.moveCallback) chara.moveCallback(chara);
		}

		chara.step++;
		*/
	}, 60);


	return this;
};

Character.nextId = 1000;

Character.prototype.updateAngle = function() {
	while (this.angle < 0) this.angle = 360 + this.angle;
	this.angle2 = Math.round(this.angle * 8 / 360) * 360 / 8;
	while (this.angle2 < 0) this.angle2 = 360 + this.angle2;
	this.angle2 %= 360;
};

Character.prototype.getBoundRect = function(x, y) {
	var x1 = (x - 26 / 2), y1 = (y - 14 / 2);
	var x2 = x1 + 26, y2 = y1 + 14;
	return { 'x1' : x1, 'y1' : y1, 'x2' : x2, 'y2' : y2 };
};

Character.prototype.moveTo = function(x, y) {
	with (this.boundBox.style) {
		//visibility = 'visible';
		visibility = 'hidden';
		left = parseInt(x - 26 / 2) + 'px';
		top  = parseInt(y - 14 / 2) + 'px';
	}

	this.sprite.moveTo(this.px = x, this.py = y);

	geometry.rects['chara_' + this.id] = this.getBoundRect(this.px, this.py);
};

Character.prototype.walkTo = function(x, y, callback) {
	this.move = 1;
	this.speed = 4;
	this.sx = this.sprite.px;
	this.sy = this.sprite.py;
	this.dx = x;
	this.dy = y;
	this.distx = this.dx - this.sx;
	this.disty = this.dy - this.sy;
	this.dist = Math.pol(this.dx - this.sx, this.dy - this.sy);
	this.steps = this.dist / this.speed;
	this.step = 0;
	this.direction = { 'x' : (this.dx - this.sx) / this.steps, 'y' : (this.dy - this.sy) / this.steps };
	this.moveCallback = callback;
};

Character.prototype.lookTo = function(angle) {
	this.angle = angle;
	this.updateAngle();
};

Character.create = function(agroup, x, y, callback) {
	var agroup = 'charas/' + agroup;
	LoadAnimationGroup(agroup, function() {
		var chara = new Character(agroup);
		chara.moveTo(x, y);
		if (callback) callback(chara);
	});
};