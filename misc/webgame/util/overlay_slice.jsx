//
// averlay_slice.jsx
//   Description
//
// Copyright: (c)2007, soywiz
// Contact: soywiz@gmail.com
// NO Requires: http://ps-scripts.sourceforge.net/xtools.html
//

#target photoshop

cTID = function(s) { return app.charIDToTypeID(s); };
sTID = function(s) { return app.stringIDToTypeID(s); };

Stdlib = function Stdlib() {};

//
// Select either the Transparency or Mask Channel
// kind - "Trsp" or "Msk "
//
Stdlib.loadSelection = function(doc, layer, kind, invert) {
   function _ftn() {
     var desc = new ActionDescriptor(); // Set

     var cref = new ActionReference(); // Channel Selection
     cref.putProperty(cTID("Chnl"), cTID("fsel"));
     desc.putReference(cTID("null"), cref);

     var tref = new ActionReference(); // Channel Kind ("Trsp" or "Msk ")
     tref.putEnumerated(cTID("Chnl"), cTID("Chnl"), cTID(kind));
     desc.putReference(cTID("T   "), tref);
     if (invert == true) {
       desc.putBoolean(cTID("Invr"), true);
     }
     executeAction(cTID("setd"), desc, DialogModes.NO);
   }
   Stdlib.wrapLCLayer(doc, layer, _ftn);
};
Stdlib.selectTransparencyChannel = function(doc, layer, invert) {
   Stdlib.loadSelection(doc, layer, "Trsp", invert);
};
Stdlib.selectMaskChannel = function(doc, layer, invert) {
   Stdlib.loadSelection(doc, layer, "Msk ", invert);
};

Stdlib.wrapLCLayer = function(doc, layer, ftn) {
   var ad = app.activeDocument;
   if (doc) {
     if (ad != doc) {
       app.activeDocument = doc;
     }
   } else {
     doc = ad;
   }

   var al = doc.activeLayer;
   var alvis = al.visible;

   if (layer && doc.activeLayer != layer) {
     doc.activeLayer = layer;
   } else {
     layer = doc.activeLayer;
   }

   var res = undefined;

   try {
     res = ftn(doc, layer);

   } finally {
     if (doc.activeLayer != al) {
       doc.activeLayer = al;
     }
     doc.activeLayer.visible = alvis;

     if (app.activeDocument != ad) {
       app.activeDocument = ad;
     }
   }

   return res;
};

var startRulerUnits = app.preferences.rulerUnits;
var startTypeUnits = app.preferences.typeUnits;
var startDisplayDialogs = app.displayDialogs;
app.preferences.rulerUnits = Units.PIXELS;
app.preferences.typeUnits = TypeUnits.PIXELS;
app.displayDialogs = DialogModes.NO;

function trace(s) { $.writeln(s); }
function error(s) { alert('ERROR: ' + s); trace('ERROR: ' + s); }

function runApp() {	
	if (!app.activeDocument) {
		error('Debes haber un documento seleccionado');
		return;
	}
	
	var	doc = app.activeDocument;
	var lsets = app.activeDocument.layerSets;
	var background = undefined;
	
	var layerlist = [];
	
	//trace(lsets.length);
	
	for (var m = 0; m < lsets.length; m++) {
		var layers = lsets[m].artLayers;
		var lasty = undefined;
		
		for (var n = 0; n < layers.length; n++) {
			var layer = layers[n];
			
			doc.activeLayer = layer;
			
			switch (layer.kind) {
				case LayerKind.SOLIDFILL:
					var pitem = doc.pathItems[0].subPathItems[0].pathPoints;
					lasty = 0; for (var o = 0; o < pitem.length; o++) lasty += pitem[o].leftDirection[1];
					lasty /= pitem.length;
				break;
				case LayerKind.NORMAL:
					layerlist[layerlist.length] = { 'center' : parseInt(layer.bounds[3]), 'layer' : layer };
				break;
			}
		}
	
		if (lasty !== undefined) layerlist[layerlist.length - 1].center = lasty;
	}

	var layers = app.activeDocument.artLayers;
		
	for (var n = 0; n < layers.length; n++) {
		var layer = layers[n];
		
		doc.activeLayer = layer;
		
		switch (layer.kind) {
			case LayerKind.SOLIDFILL:
				var pitem = doc.pathItems[0].subPathItems[0].pathPoints;
				lastline = { 'p1' : pitem[0].leftDirection, 'p2' : pitem[0].leftDirection };
			break;
			case LayerKind.NORMAL:
				if (layer.isBackgroundLayer) {
					if (background !== undefined) {
						error('Solo debe haber una capa fondo');
						return;
					}
					background = layer;
				} else {
					layerlist[layerlist.length] = { 'center' : parseInt(layer.bounds[3]), 'layer' : layer };
				}
			break;
		}
	}

	// Comprobamos que haya una capa de fondo de dónde obtener los colores
	if (background === undefined) {
		error('Debe haber una capa de fondo');
		return;
	}

	var overlayers = [];

	// Función que procesa una capa
	function processLayer(doc, layerinfo, bglayer, id) {
		var layer = layerinfo.layer;
		doc.activeLayer = layer;
		Stdlib.selectTransparencyChannel(doc, layer, false);
		doc.activeLayer = bglayer;
		doc.selection.copy(false);

		var bounds = doc.selection.bounds;
		var size = { 'left' : parseInt(bounds[0]), 'top' : parseInt(bounds[1]), 'width' : parseInt(bounds[2]) - parseInt(bounds[0]), 'height' : parseInt(bounds[3]) - parseInt(bounds[1]) };
		
		var newDoc = app.documents.add(size.width, size.height, 72, layer.name);
		newDoc.paste(false);
		for (var n = 0; n < newDoc.layers.length; n++) {
			var clayer = newDoc.layers[n]; if (!clayer.isBackgroundLayer) continue;
			clayer.remove();
		}
		
		var docname = doc.name.split('.', 2)[0];
		var path = doc.path.toString() + '/' + docname;
		while (id.length < 3) id = '0' + id;

		var options = new PNGSaveOptions();
		newDoc.saveAs(new File(path + '_' + id + '.png'), options);

		if (false) {
			var finfo = new File(path + '_' + id + '.txt');
				finfo.open('w');		
				finfo.writeln(size.left + ',' + size.top + ',' + size.width + ',' + size.height);		
			finfo.close();
		}
	
		overlayers[overlayers.length] = { 'size' : size, 'name' : docname + '_' + id + '.png', 'centery' : layerinfo.center - size.top };
		
		newDoc.close();	
		app.activeDocument = doc;		
	}

	// Función que procesa una capa
	function processBackground(doc, bglayer) {
		doc.activeLayer = bglayer;
		doc.selection.selectAll();
		doc.selection.copy(false);

		var bounds = doc.selection.bounds;
		var size = { 'left' : parseInt(bounds[0]), 'top' : parseInt(bounds[1]), 'width' : parseInt(bounds[2]) - parseInt(bounds[0]), 'height' : parseInt(bounds[3]) - parseInt(bounds[1]) };
		
		var newDoc = app.documents.add(size.width, size.height, 72, layer.name);
		newDoc.paste(false);

		var docname	= doc.name.split('.', 2)[0];
		var path = doc.path.toString() + '/' + docname;
		var options = new JPEGSaveOptions();
		options.quality = 8;
		newDoc.saveAs(new File(path + '.jpg'), options, false);
		
		if (true) {
			var finfo = new File(path + '.js'); {
				finfo.open('w');		
				finfo.writeln("Background.set('images/" + docname + ".jpg', " + size.width + ", " + size.height + ");");
				for (var n = 0; n < overlayers.length; n++) {
					var ol = overlayers[n];
					finfo.writeln(
						"Background.addOver('images/" + ol.name + "'" +
						", " + ol.size.left +
						", " + ol.size.top  +
						", " + ol.size.width +
						", " + ol.size.height +
						", " + ol.centery +
						");"
					);
				}
			} finfo.close();
		}
		
		newDoc.close(SaveOptions.DONOTSAVECHANGES);
	}

	for (var n = 0; n < layerlist.length; n++) {
		var layerinfo = layerlist[n]; if (layerinfo.layer.isBackgroundLayer) continue;
		processLayer(doc, layerinfo, background, n);
	}

	processBackground(doc, background);

	doc.selection.deselect();
}

runApp();
