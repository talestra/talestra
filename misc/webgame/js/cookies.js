// Creamos namespace para cookies
var Cookie = {};

// Definimos una cookie
Cookie.set = function(name, value, expires, path, domain, secure) {
	document.cookie =
		name + "=" + escape(value) +
		((expires) ? "; expires=" + expires.toGMTString() : "") +
		((path) ? "; path=" + path : "") +
		((domain) ? "; domain=" + domain : "") +
		((secure) ? "; secure" : "");
};

// Definimos una cookie que no expira
Cookie.setForever = function(name, value) {
	setCookie(name, value, new Date((new Date()).getFullYear() + 10, 01, 01));
};

// Obtenemos una cookie
Cookie.get = function(name) {
	var dc = document.cookie;
	var prefix = name + "=";

	var begin = dc.indexOf("; " + prefix);
	if (begin == -1) {
		begin = dc.indexOf(prefix);
		if (begin != 0) return undefined;
	} else {
		begin += 2;
	}
	var end = document.cookie.indexOf(";", begin);

	if (end == -1) end = dc.length;

	return unescape(dc.substring(begin + prefix.length, end));
};

// Borramos una cookie
Cookie.remove = function(name, path, domain) {
	if (getCookie(name)) {
		document.cookie = (
			name + "=" +
			((path) ? "; path=" + path : "") +
			((domain) ? "; domain=" + domain : "") +
			"; expires=Thu, 01-Jan-70 00:00:01 GMT"
		);
	}
};