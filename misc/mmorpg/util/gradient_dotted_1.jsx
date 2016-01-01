#target photoshop

app.bringToFront();

var startRulerUnits = app.preferences.rulerUnits
var startTypeUnits = app.preferences.typeUnits
var startDisplayDialogs = app.displayDialogs
app.preferences.rulerUnits = Units.PIXELS
app.preferences.typeUnits = TypeUnits.PIXELS
app.displayDialogs = DialogModes.NO
//app.preferences.numberOfHistoryStates = 1;
app.preferences.numberOfHistoryStates = 3;

app.bringToFront();

function getRawImage(docRef) {
    var desc1 = new ActionDescriptor();
    var desc2 = new ActionDescriptor();
	var fileName = Folder.temp.fsName + "\\gradient_dotted_temp.raw";
	
	if (!docRef) return { 'width': 0, 'height': 0, 'data': '' };
	
	var backActiveDocument = activeDocument;
	
	activeDocument = docRef;

    desc1.putBoolean(stringIDToTypeID("channelsInterleaved"), false);
    desc2.putObject(stringIDToTypeID("as"), stringIDToTypeID("rawFormat"), desc1);
    desc2.putPath(stringIDToTypeID("in"), new File(fileName));
    desc2.putBoolean(stringIDToTypeID("copy"), true);
    desc2.putBoolean(stringIDToTypeID("lowerCase"), true);
    executeAction(stringIDToTypeID("save"), desc2, DialogModes.NO);
	
    var inFile = new File(fileName);
    inFile.encoding = "BINARY";
    inFile.open("r:");
    var rawFileBuffer = inFile.read();
    inFile.close();
	inFile.remove();
	
	activeDocument = backActiveDocument;
	
    return { 'width': parseInt(docRef.width.value), 'height': parseInt(docRef.height.value), 'data': rawFileBuffer.substr(0, docRef.width * docRef.height) };
}

var ui = (
	"dialog { \
		alignChildren: 'fill', \
		text: 'Generador de Gradiente Punteado 1.0 por soywiz@gmail.com', \
		options: Panel { \
			orientation: 'column', alignChildren:'left', \
			text: 'Opciones', \
			imgWidth: Group { \
				orientation: 'row', alignChildren:'left', \
				st: StaticText { text: 'Ancho de Imagen:', preferredSize: [120, 20] } \
				et: EditText { text: '1024', preferredSize: [180, 20] } \
			}, \
			imgHeight: Group { \
				orientation: 'row', alignChildren:'left', \
				st: StaticText { text: 'Alto de Imagen:', preferredSize: [120, 20] } \
				et: EditText { text: '1024', preferredSize: [180, 20] } \
			}, \
			cellWidth: Group { \
				orientation: 'row', alignChildren:'left', \
				st: StaticText { text: 'Ancho de Celda:', preferredSize: [120, 20] } \
				et: EditText { text: '64', preferredSize: [180, 20] } \
			}, \
			cellHeight: Group { \
				orientation: 'row', alignChildren:'left', \
				st: StaticText { text: 'Alto de Celda:', preferredSize: [120, 20] } \
				et: EditText { text: '64', preferredSize: [180, 20] } \
			}, \
			rBlur: Group { \
				orientation: 'row', alignChildren:'left', \
				st: StaticText { text: 'Blur de radio:', preferredSize: [120, 20] } \
				et: EditText { text: '4', preferredSize: [180, 20] } \
			} \
			rDocument: Group { \
				orientation: 'row', alignChildren:'left', \
				st: StaticText { text: 'Documento:', preferredSize: [120, 20] } \
				dl: DropDownList { preferredSize: [180, 20] } \
			} \
		}, \
		gButtons: Group { \
			orientation: 'row', alignment: 'right', \
			okBtn: Button { text:'Generar', properties:{name:'ok'} }, \
			cancelBtn: Button { text:'Cancelar', properties:{name:'cancel'} } \
		} \
	}"
);

var win = new Window (ui);

for (var n = 0; n < app.documents.length; n++) {
	var item = win.options.rDocument.dl.add('item', app.documents[n].name);
	item.document = app.documents[n];
	if (app.documents[n] == activeDocument) win.options.rDocument.dl.selection = item;
}

win.center();

var ret = win.show();

if (ret == 1) {
	try {	
		function makeCircle(x, y, r) {
			var lineArray = [];
			
			lineArray[0] = new PathPointInfo;
			lineArray[0].kind = PointKind.CORNERPOINT;
			lineArray[0].anchor = [x + r, y];
			lineArray[0].leftDirection = lineArray[0].anchor;
			lineArray[0].rightDirection = lineArray[0].anchor;
			
			lineArray[1] = new PathPointInfo;
			lineArray[1].kind = PointKind.CORNERPOINT;
			lineArray[1].anchor = [x, y - r];
			lineArray[1].leftDirection = [x - r, y - r];
			lineArray[1].rightDirection = [x + r, y - r];
			
			lineArray[2] = new PathPointInfo;
			lineArray[2].kind = PointKind.CORNERPOINT;
			lineArray[2].anchor = [x - r, y];
			lineArray[2].leftDirection = lineArray[2].anchor;
			lineArray[2].rightDirection = lineArray[2].anchor;

			lineArray[3] = new PathPointInfo;
			lineArray[3].kind = PointKind.CORNERPOINT;
			lineArray[3].anchor = [x, y + r];
			lineArray[3].leftDirection = [x + r, y + r];
			lineArray[3].rightDirection = [x - r, y + r];
			
			var lineSubPath = new SubPathInfo();
			lineSubPath.operation = ShapeOperation.SHAPEXOR;
			lineSubPath.closed = true;
			lineSubPath.entireSubPath = lineArray;		
			
			return lineSubPath;
		}

		var imgWidth   = parseInt(win.options.imgWidth.et.text);
		var imgHeight  = parseInt(win.options.imgHeight.et.text);
		var cellWidth  = parseInt(win.options.cellWidth.et.text);
		var cellHeight = parseInt(win.options.cellHeight.et.text);
		var rBlur      = parseInt(win.options.rBlur.et.text);
		var maxRad     = Math.min(cellWidth, cellHeight) * 0.499;
		var document   = win.options.rDocument.dl.selection.document;
		
		if (parseInt(document.width.value) > 512) throw('El ancho de la imagen supera los 512 pixeles (' + document.width.value + 'x' + document.height.value + '). Cancelando...');
		if (parseInt(document.height.value) > 512) throw('El alto de la imagen supera los 512 pixeles (' + document.width.value + 'x' + document.height.value + '). Cancelando...');
		
		var image = getRawImage(document);
			
		var docRef = app.documents.add(imgWidth, imgHeight, 72, "Simple Line");
		
		docRef.artLayers.add();
		docRef.activeLayer.name = "Dots"; 
		
		var width = docRef.width, height = docRef.height;
		var cols = width / cellWidth, rows = height / cellHeight;
		
		var lineSubPathArray = [];

		var blockWidth  = parseInt(image.width / cols);
		var blockHeight = parseInt(image.height / rows);
		
		function flushCircles() {
			if (!lineSubPathArray.length) return;
			var myPathItem = docRef.pathItems.add("gradient_dotted_shape", lineSubPathArray);
			myPathItem.makeSelection(rBlur, true, SelectionType.EXTEND);	
			docRef.pathItems.removeAll();
			lineSubPathArray.length = 0;
		}
		
		var subshapes = 0;
		for (var y = 0; y < rows; y++) {
			for (var x = 0; x < cols; x++) {
				var pixel = 0, n = 0;
				for (var y1 = 0; y1 < blockHeight; y1++) {
					for (var x1 = 0; x1 < blockWidth; x1++) {
						var rx = x * blockWidth + x1, ry = y * blockWidth + y1;
						pixel += image.data.charCodeAt(ry * image.width + rx) / 255;
						n++;
					}
				}
				pixel = pixel / n;
				var cx = x * width / cols + (width / cols / 2), cy = y * height / rows + (height / rows / 2);
				lineSubPathArray[lineSubPathArray.length] = makeCircle(cx, cy, pixel * maxRad);
				if (lineSubPathArray.length >= 0x100) flushCircles();
			}
		}

		flushCircles();
	
		docRef.selection.fill(app.foregroundColor);
		
		docRef.selection.deselect();
		
		preferences.rulerUnits = startRulerUnits;
		preferences.typeUnits = startTypeUnits;
		displayDialogs = startDisplayDialogs;

		app.refresh();
		
		app.bringToFront();
	} catch(e) {
		alert(e);
	}
}