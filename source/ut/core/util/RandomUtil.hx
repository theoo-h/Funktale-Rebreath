package ut.core.util;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class RandomUtil {
	public static var MASK_MAX_TRIES:Int = 10;

	public static function maskRandomPosition(rect:FlxRect, avoid:FlxRect, time:Float, seed:Int, ?maxTries:Null<Int>):FlxPoint {
		if (maxTries == null)
			maxTries = MASK_MAX_TRIES;

		for (i in 0...maxTries) {
			final t = time + i * 0.173;
			final pos = randomPosition(rect, t, seed);
			if (!avoid.containsXY(pos.x, pos.y)) {
				return pos;
			}
		}

		return FlxPoint.get(rect.x + rect.width * 0.5, rect.y + rect.height * 0.5);
	}

	public static function randomPosition(rect:FlxRect, time:Float, seed:Int):FlxPoint {
		var input = time * 92821.735 + seed * 0.531;

		var xNoise = FlxMath.fastSin(input) * 0.5 + 0.5;
		var yNoise = FlxMath.fastSin(input * 1.3241 + 42.69) * 0.5 + 0.5;

		return FlxPoint.get(rect.x + xNoise * rect.width, rect.y + yNoise * rect.height);
	}
}
