package brave;
import nme.events.Event;
import nme.utils.Timer;

/**
 * ...
 * @author 
 */

class Animation 
{

	public function new() 
	{
		
	}
	
	static public function Linear(input:Float):Float {
		return input;
	}

	static public function Sin(input:Float):Float {
		return Math.sin(input * Math.PI * 0.5);
	}

	static public function animate(done:Void -> Void, totalTime:Float, object:Dynamic, properties:Dynamic, ?easing:Float -> Float, ?stepCallback:Float -> Void):Void {
		if (easing == null) easing = Linear;
		
		if (totalTime == 0)
		{
			for (property in Reflect.fields(properties)) {
				var finalValue = Reflect.getProperty(properties, property);
				Reflect.setProperty(object, property, finalValue);
			}
			if (done != null) done();
		}
		else
		{
			var startTime:Float = haxe.Timer.stamp();
			var timer:Timer = new Timer(20);
			
			var initialProperties:Dynamic = { };
			var finalProperties:Dynamic = { };
			
			//Reflect.getProperty
			
			for (property in Reflect.fields(properties)) {
				Reflect.setProperty(initialProperties, property, Reflect.getProperty(object, property));
				Reflect.setProperty(finalProperties, property, Reflect.getProperty(properties, property));
			}
			
			var onTick = null;
			
			onTick = function(e:Event):Void {
				var currentTime:Date = Date.now();
				var elapsedPercentage:Float;
				if (totalTime >= 0) {
					elapsedPercentage = (MathEx.clamp(haxe.Timer.stamp() - startTime, 0, totalTime) / totalTime);
				} else {
					elapsedPercentage = 1;
				}
				
				for (property in Reflect.fields(properties)) {
					var initialValue = Reflect.getProperty(initialProperties, property);
					var finalValue = Reflect.getProperty(finalProperties, property);
					var interpolatedValue = MathEx.interpolate(easing(elapsedPercentage), 0, 1, initialValue, finalValue);
					//BraveLog.trace("value : " + property + " : " + interpolatedValue);
					Reflect.setProperty(object, property, interpolatedValue);
				}

				if (stepCallback != null) {
					stepCallback(elapsedPercentage);
				}

				if (elapsedPercentage == 1) {
					timer.stop();
					timer.removeEventListener("timer", onTick);
					if (done != null) done();
				}
			};
			
			timer.addEventListener("timer", onTick);
			timer.start();
			onTick(null);
		}
	}
}