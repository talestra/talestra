package brave.sprites;
import nme.display.Sprite;

/**
 * ...
 * @author 
 */

class UISprite extends Sprite
{
	
	public var textSprite:TextSprite;

	public function new() 
	{
		super();

		addChild(textSprite = new TextSprite());
	}
	
}