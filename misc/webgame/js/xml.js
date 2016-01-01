var XmlHTTP = {};

// Obtenemos el objeto de Ajax
XmlHTTP.Get = function() {
	var xmlhttp;

	try {
		xmlhttp = new XMLHttpRequest();
	} catch (e) {
		try {
			xmlhttp = new ActiveXObject('Msxml2.XMLHTTP');
		} catch (e) {
			xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
		}
	}

	return xmlhttp;
};

// Obtenemos los datos de una dirección y, al terminar llamamos a una función callback.
XmlHTTP.GetData = function(url, callback, xml) {
	var xmlhttp = this.Get();

	xmlhttp.onreadystatechange = function() {
		if (xmlhttp.readyState == 4) {
			switch (xmlhttp.status) {
				case 0: case 200: if (callback) callback(xml ? xmlhttp.responseXML : xmlhttp.responseText); break;
				default: if (callback) callback(undefined); break;
			}
		}
	};

	xmlhttp.open('GET', url, true);
	xmlhttp.send('');
};

// Obtenemos el XML de una dirección y, al terminar llamamos a una función callback.
XmlHTTP.GetXML = function(url, callback, xml) {
	return this.GetData(url, callback, true);
};