package brave.sprites;
import brave.SpriteUtils;
import nme.display.Graphics;
import nme.display.Sprite;
import nme.text.TextField;
import nme.text.TextFormat;

/**
 * ...
 * @author 
 */

class GameSprite extends Sprite
{
	public var mapSprite:Sprite;
	public var backgroundBack:Sprite;
	public var backgroundFront:Sprite;
	public var ui:UISprite;

	public function new() 
	{
		super();
		
		BraveAssets.getBitmapData("PG_MAIN");
		
		addChild(mapSprite = new Sprite());
		addChild(backgroundBack = new Sprite());
		addChild(backgroundFront = new Sprite());
		addChild(ui = new UISprite());
		
		backgroundBack.addChild(SpriteUtils.createSolidRect(0x000000));
		backgroundFront.addChild(SpriteUtils.createSolidRect(0x000000));
	}
}