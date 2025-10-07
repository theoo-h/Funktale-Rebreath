package ut.core.util;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxDirectionFlags;

class CollisionUtil {
	private static var _sinAng:Float = 0;
	private static var _cosAng:Float = 1;

	private static var _lastAng:Float = 0;

	private static var _sinMAng:Float = 0;
	private static var _cosMAng:Float = 1;

	private static var _lastMAng:Float = 0;

	private static var _sinFAng:Float = 0;
	private static var _cosFAng:Float = 1;

	private static var _lastFAng:Float = 0;

	public static function aabbCollision(soul:FlxObject, box:FlxObject, angle:Float, slidingAllowed:Bool, groundFlags:Array<Int>):Array<FlxDirectionFlags> {
		final boxCenter = box.getMidpoint();

		if (-angle != _lastAng) {
			final rads = -angle * Math.PI / 180;
			_sinAng = FlxMath.fastSin(rads);
			_cosAng = FlxMath.fastCos(rads);
			_lastAng = -angle;
		}

		if (angle != _lastMAng) {
			final rads = angle * Math.PI / 180;
			_sinMAng = FlxMath.fastSin(rads);
			_cosMAng = FlxMath.fastCos(rads);
			_lastMAng = angle;
		}

		var fak = (angle - soul.angle);
		if (fak != _lastFAng) {
			final rads = fak * Math.PI / 180;
			_sinFAng = FlxMath.fastSin(rads);
			_cosFAng = FlxMath.fastCos(rads);
			_lastFAng = fak;
		}

		final sepData = getSeparationFromBox(soul.x, soul.y, soul, box, boxCenter);
		final sepX = sepData.sepX;
		final sepY = sepData.sepY;
		final collidedFaces = sepData.faces;

		if (sepX != 0 || sepY != 0) {
			var worldSepX = sepX * _cosMAng - sepY * _sinMAng;
			var worldSepY = sepX * _sinMAng + sepY * _cosMAng;
			soul.x += worldSepX;
			soul.y += worldSepY;

			if (slidingAllowed) {
				for (face in collidedFaces) {
					if (groundFlags.indexOf(face) >= 0) {
						var slopeX = 0.0;
						var slopeY = 0.0;

						switch (face) {
							case FlxDirectionFlags.LEFT:
								slopeX = -_sinFAng;
								slopeY = -_cosFAng;
							case FlxDirectionFlags.RIGHT:
								slopeX = _sinFAng;
								slopeY = _cosFAng;
							case FlxDirectionFlags.UP:
								slopeX = _sinFAng;
								slopeY = -_cosFAng;
							case FlxDirectionFlags.DOWN:
								slopeX = _sinFAng;
								slopeY = _cosFAng;
							default:
								// fuckinig shit
						}

						if (Math.abs(slopeX) < FlxMath.EPSILON)
							slopeX = 0;
						if (Math.abs(slopeY) < FlxMath.EPSILON)
							slopeY = 0;

						// trace('face: $face, boxA: ${box.angle}, soulA: ${soul.angle}, x: $slopeX, y: $slopeY');
						var slideSpeed = 1.5;
						var newX = soul.x + slopeX * slideSpeed;
						var newY = soul.y + slopeY * slideSpeed;

						final testSep = getSeparationFromBox(newX, newY, soul, box, boxCenter);
						if (testSep.sepX == 0 && testSep.sepY == 0) {
							soul.x = newX;
							soul.y = newY;
						}
					}
				}
			}
		}

		boxCenter.put();
		return collidedFaces;
	}

	private static function getSeparationFromBox(soulX:Float, soulY:Float, soul:FlxObject, box:FlxObject, boxCenter:FlxPoint):{
		sepX:Float,
		sepY:Float,
		faces:Array<FlxDirectionFlags>
	} {
		var localX = soulX + soul.width / 2 - boxCenter.x;
		var localY = soulY + soul.height / 2 - boxCenter.y;
		var rotatedX = localX * _cosAng - localY * _sinAng;
		var rotatedY = localX * _sinAng + localY * _cosAng;

		var halfW = box.width / 2;
		var halfH = box.height / 2;

		var left = rotatedX - soul.width / 2;
		var right = rotatedX + soul.width / 2;
		var top = rotatedY - soul.height / 2;
		var bottom = rotatedY + soul.height / 2;

		var sepX = 0.0;
		var sepY = 0.0;
		var collidedFaces:Array<FlxDirectionFlags> = [];

		if (left < -halfW) {
			sepX = -halfW - left;
			collidedFaces.push(FlxDirectionFlags.LEFT);
		} else if (right > halfW) {
			sepX = halfW - right;
			collidedFaces.push(FlxDirectionFlags.RIGHT);
		}

		if (top < -halfH) {
			sepY = -halfH - top;
			collidedFaces.push(FlxDirectionFlags.UP);
		} else if (bottom > halfH) {
			sepY = halfH - bottom;
			collidedFaces.push(FlxDirectionFlags.DOWN);
		}

		return {sepX: sepX, sepY: sepY, faces: collidedFaces};
	}
}
