//
// averlay_slice.jsx
//   Description
//
// Copyright: (c)2007, soywiz
// Contact: soywiz@gmail.com
// Parte del código: http://ps-scripts.sourceforge.net/xtools.html
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
		if (invert == true) desc.putBoolean(cTID("Invr"), true);
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
	
	var rdoc = app.activeDocument;
	var objectDoc = app.documents.add(1, 1, 72, doc.name + '_object');
	app.activeDocument = rdoc;
	
	var docname = rdoc.name.split('.', 2)[0];
	var path = rdoc.path.toString() + '/' + docname;	
	
	// Función que procesa una capa
	function processLayer(doc, layerinfo, bglayer, id) {
		var layer = layerinfo.layer;
		doc.activeLayer = layer;
		Stdlib.selectTransparencyChannel(doc, layer, false);
		doc.activeLayer = bglayer;		
		doc.selection.copy(false);

		var bounds = doc.selection.bounds;
		var size = { 'left' : parseInt(bounds[0]), 'top' : parseInt(bounds[1]), 'width' : parseInt(bounds[2]) - parseInt(bounds[0]), 'height' : parseInt(bounds[3]) - parseInt(bounds[1]) };
		
		var odsize = { 'width' : objectDoc.width, 'height' : objectDoc.height };
		
		if (odsize.width <= 1) odsize = { 'width' : 0, 'height' : 0 };
		
		app.activeDocument = objectDoc;
		
		objectDoc.resizeCanvas(odsize.width + size.width + 1, Math.max(odsize.height, size.height), AnchorPosition.TOPLEFT);
		
		var x1 = odsize.width;
		var x2 = odsize.width + size.width + 1;
		var y1 = 0;
		var y2 = size.height + 1;
		
		objectDoc.selection.select([[x1, y1], [x2, y1], [x2, y2], [x1, y2]], SelectionType.REPLACE, 0, false);
		objectDoc.paste(false);
		
		for (var n = 0; n < objectDoc.layers.length; n++) {
			var clayer = objectDoc.layers[n]; if (!clayer.isBackgroundLayer) continue;
			clayer.remove();
		}
		
		overlayers[overlayers.length] = {
			'size' : size,
			'x'    : x1,
			'name' : docname + '_' + id + '.png',
			'centery' : layerinfo.center - size.top
		};
		
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

		var options = new JPEGSaveOptions(); options.quality = 8;
		newDoc.saveAs(new File(path + '.jpg'), options, false);
		
		if (true) {
			var finfo = new File(path + '.xml'); {
				finfo.open('w');
				finfo.writeln('<?xml version="1.0" encoding="ISO-8859-1" ?>');
				finfo.writeln('<agroup name="' + docname + '" objects="' + parseInt(overlayers.length) + '">');
				finfo.writeln("\t" + '<image id="background" file="' + docname + '.jpg"         width="' + parseInt(newDoc.width) + '" height="' + parseInt(newDoc.height) + '" />');
				finfo.writeln("\t" + '<image id="objects"    file="' + docname + '_objects.png" width="' + parseInt(objectDoc.width) + '" height="' + parseInt(objectDoc.height) + '" />');
				finfo.writeln("\t");
				finfo.writeln("\t" + '<cut id="background" imageid="background" x="0" y="0" width="' + parseInt(newDoc.width) + '" height="' + parseInt(newDoc.height) + '" centerx="0" centery="0" />');
				for (var n = 0; n < overlayers.length; n++) {
					var ol = overlayers[n];
					finfo.writeln("\t" + '<cut id="object' + n + '" imageid="objects" x="' + parseInt(ol.x) + '" y="0" width="' + parseInt(ol.size.width) + '" height="' + parseInt(ol.size.height) + '" centerx="0" centery="' + parseInt(ol.centery) + '" />');
				}
				finfo.writeln("\t");
				finfo.writeln("\t" + '<animation id="background"><frame time="1"><put cutid="background" x="0" y="0" /></frame></animation>');
				for (var n = 0; n < overlayers.length; n++) {
					finfo.writeln("\t" + '<animation id="object' + n + '"><frame time="1"><put cutid="object' + n + '" x="0" y="0" /></frame></animation>');
				}
				finfo.writeln("\t");
				for (var n = 0; n < overlayers.length; n++) {
					var ol = overlayers[n];
					finfo.writeln("\t" + '<point id="' + n + '" x="' + parseInt(ol.size.left) + '" y="' + (parseInt(ol.size.top) + parseInt(ol.centery)) + '" />');
				}
				finfo.writeln('</agroup>');
			} finfo.close();
		}
		
		newDoc.close(SaveOptions.DONOTSAVECHANGES);
	}

	// Procesamos las capas
	for (var n = 0; n < layerlist.length; n++) {		
		var layerinfo = layerlist[n]; if (layerinfo.layer.isBackgroundLayer) continue;
		processLayer(doc, layerinfo, background, n);
	}

	app.activeDocument = objectDoc;	

	objectDoc.saveAs(new File(path + '_objects.png'), new PNGSaveOptions());

	app.activeDocument = doc;	

	// Procesamos el fondo
	processBackground(doc, background);

	// Eliminamos la selección del documento
	doc.selection.deselect();

	app.activeDocument = objectDoc;	
	objectDoc.close(SaveOptions.DONOTSAVECHANGES);	

	app.activeDocument = doc;	
}

runApp();
