package brave.sprites;
import brave.Animation;
import brave.BraveAssets;
import brave.SpriteUtils;
import brave.StringEx;
import haxe.Log;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.text.TextField;
import nme.text.TextFormat;

using brave.SpriteUtils;

/**
 * ...
 * @author 
 */

class TextSprite extends Sprite
{
	var picture:Sprite;
	var textContainer:Sprite;
	var textBackground:Sprite;
	var titleTextField:TextField;
	var textTextField:TextField;
	var padding:Int = 16;
	var boxWidth:Int = 600;
	var boxHeight:Int = 100;
	var animateText:Bool = false;

	public function new() 
	{
		super();
		
		textContainer = new Sprite();
		textBackground = new Sprite();
		textTextField = new TextField();
		picture = new Sprite();
		picture.x = 0;
		picture.y = 480;
		
		textContainer.addChild(textBackground);
		textContainer.addChild(textTextField);
		
		textTextField.defaultTextFormat = new TextFormat("Arial", 16, 0xFFFFFF);
		textTextField.selectable = false;
		textTextField.multiline = true;
		textTextField.text = "";
		
		setTextSize(false);
		
		//textField.textColor = 0xFFFFFF;
		
		this.alpha = 0;
		
		addChild(picture);
		addChild(textContainer);
	}
	
	private function setTextSize(withFace:Bool):Void {
		var faceWidth:Int = withFace ? 200 : 0;
		
		SpriteUtils.extractSpriteChilds(textBackground);
		textBackground.addChild(SpriteUtils.createSolidRect(0x000000, 0.5, boxWidth - faceWidth, boxHeight));
		
		textContainer.x = 640 / 2 - boxWidth / 2 + faceWidth;
		textContainer.y = 480 - boxHeight - 20;

		textTextField.width = boxWidth - padding * 2 - faceWidth;
		textTextField.height = boxHeight - padding * 2;
		textTextField.x = padding;
		textTextField.y = padding;
	}
	
	private function setText(faceId:Int, title:String, text:String, done:Void -> Void):Void {
		if (animateText) {
			var obj:Dynamic = { showChars : 0 };
			var time:Float = text.length * 0.01;
			Animation.animate(done, time, obj, { showChars : text.length } , Animation.Linear, function(step:Float) {
				textTextField.text = text.substr(0, Std.int(obj.showChars));
			} );
		} else {
			textTextField.text = text;
			done();
		}
	}

	public function setTextAndEnable(faceId:Int, title:String, text:String, done:Void -> Void):Void {
		SpriteUtils.extractSpriteChilds(picture);
		setTextSize(faceId >= -1);
		if (faceId >= 0) {
			var bitmapData:BitmapData = BraveAssets.getBitmapDataWithAlphaCombined(StringEx.sprintf("Z_%02d_%02d", [Std.int(faceId / 100), Std.int(faceId % 100)]));
			var bmp:Bitmap = new Bitmap(bitmapData).center(0, 1);
			picture.addChild(bmp);
		}

		enable(function() {
			setText(faceId, title, text, done);
		});
	}

	public function enable(done:Void -> Void):Void {
		if (alpha != 1) {
			Animation.animate(done, 0.3, this, { alpha : 1 } );
		} else {
			done();
		}
	}
	
	public function endText():Void {
		textTextField.text = "";
	}

	public function disable(done:Void -> Void):Void {
		var done2 = function() {
			endText();
			done();
		};
		if (alpha != 0) {
			Animation.animate(done2, 0.1, this, { alpha : 0 } );
		} else {
			done2();
		}
	}
}