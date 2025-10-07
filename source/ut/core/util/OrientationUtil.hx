package ut.core.util;

import flixel.util.FlxDirectionFlags;

class OrientationUtil {
	public static function getGrounds(boxAngle:Float, gravityAngle:Float):Array<FlxDirectionFlags> {
		var normalizedBox = boxAngle % 360;
		if (normalizedBox < 0)
			normalizedBox += 360;

		var normalizedGravity = gravityAngle % 360;
		if (normalizedGravity < 0)
			normalizedGravity += 360;

		var rAngle = ((normalizedBox - normalizedGravity + 360) % 360);

		var dirs:Array<Int>;

		if (rAngle >= 0 && rAngle < 30) {
			dirs = [0x1000]; // down
		} else if (rAngle >= 30 && rAngle < 55) {
			dirs = [0x1000, 0x0010]; // down, right
		} else if (rAngle >= 55 && rAngle < 115) {
			dirs = [0x0010]; // right
		} else if (rAngle >= 115 && rAngle < 155) {
			dirs = [0x0010, 0x0100]; // right, up
		} else if (rAngle >= 155 && rAngle < 215) {
			dirs = [0x0100]; // up
		} else if (rAngle >= 215 && rAngle < 240) {
			dirs = [0x0100, 0x0001]; // up, left
		} else if (rAngle >= 240 && rAngle < 300) {
			dirs = [0x0001]; // left
		} else if (rAngle >= 300 && rAngle < 340) {
			dirs = [0x0001, 0x1000]; // left, down
		} else {
			dirs = [0x1000]; // down
		}

		return dirs;
	}
}
