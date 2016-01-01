Math.angle = function(x1, y1, x2, y2, anglec) {
	var x = x2 - x1, y = y2 - y1;
	var dist = Math.sqrt(x * x + y * y);

	if (!anglec) y = -y;

	if (x2 >= x1 && y2 >= y1) {
		return Math.asin(y / dist) * 360 / (Math.PI * 2);
	} else if (x2 < x1 && y2 >= y1) {
		return 180 - Math.asin(y / dist) * 360 / (Math.PI * 2);
	} else if (x2 <= x1 && y2 < y1) {
		return 180 + -Math.asin(y / dist) * 360 / (Math.PI * 2);
	} else {
		return 360 + Math.asin(y / dist) * 360 / (Math.PI * 2);
	}
};

Math.pol = function(x, y) { return Math.sqrt(x * x + y * y); };
Math.dist = function(x1, y1, x2, y2) { return Math.pol(x2 - x1, y2 - y1); };
Math.sign = function(a) { return (a == 0) ? 0 : ((a > 0) ? 1 : -1); };
