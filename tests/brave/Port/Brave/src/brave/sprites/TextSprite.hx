package brave.sprites;
import brave.Animation;
import brave.SpriteUtils;
import haxe.Log;
import nme.display.Sprite;
import nme.text.TextField;
import nme.text.TextFormat;

/**
 * ...
 * @author 
 */

class TextSprite extends Sprite
{
	var titleTextField:TextField;
	var textTextField:TextField;
	var padding:Int = 16;
	var boxWidth:Int = 600;
	var boxHeight:Int = 100;
	var animateText:Bool = false;

	public function new() 
	{
		super();
		
		textTextField = new TextField();
		addChild(SpriteUtils.createSolidRect(0x000000, 0.5, boxWidth, boxHeight));
		addChild(textTextField);
		textTextField.defaultTextFormat = new TextFormat("Arial", 16, 0xFFFFFF);
		textTextField.selectable = false;
		textTextField.multiline = true;
		textTextField.text = "";
		textTextField.width = boxWidth - padding * 2;
		textTextField.height = boxHeight - padding * 2;
		textTextField.x = padding;
		textTextField.y = padding;
		
		x = 640 / 2 - boxWidth / 2;
		y = 480 - boxHeight - 20;
		//textField.textColor = 0xFFFFFF;
		
		this.alpha = 0;
	}
	
	public function setText(title:String, text:String, done:Void -> Void):Void {
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

	public function setTextAndEnable(title:String, text:String, done:Void -> Void):Void {
		
		enable(function() {
			setText(title, text, done);
		});
	}

	public function enable(done:Void -> Void):Void {
		if (alpha != 1) {
			Animation.animate(done, 0.5, this, { alpha : 1 } );
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
			Animation.animate(done2, 0.5, this, { alpha : 0 } );
		} else {
			done2();
		}
	}
}