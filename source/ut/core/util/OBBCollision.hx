package ut.core.util;

import flixel.FlxObject;
import flixel.math.FlxPoint;

class OBBCollision {
	public static function check(a:FlxObject, b:FlxObject):Bool {
		var cxA = a.x + a.width * 0.5;
		var cyA = a.y + a.height * 0.5;
		var hxA = a.width * 0.5;
		var hyA = a.height * 0.5;

		var cxB = b.x + b.width * 0.5;
		var cyB = b.y + b.height * 0.5;
		var hxB = b.width * 0.5;
		var hyB = b.height * 0.5;

		var angleA = a.angle * Math.PI / 180;
		var angleB = b.angle * Math.PI / 180;

		getOBBCorners(cxA, cyA, hxA, hyA, angleA, _cornersA);
		getOBBCorners(cxB, cyB, hxB, hyB, angleB, _cornersB);

		_axes[0] = getEdgeNormal(_cornersA[0], _cornersA[1], _axes[0]);
		_axes[1] = getEdgeNormal(_cornersA[1], _cornersA[2], _axes[1]);
		_axes[2] = getEdgeNormal(_cornersB[0], _cornersB[1], _axes[2]);
		_axes[3] = getEdgeNormal(_cornersB[1], _cornersB[2], _axes[3]);

		// sat check
		for (i in 0...4) {
			var axis = _axes[i];
			if (!overlapOnAxis(_cornersA, _cornersB, axis)) {
				return false;
			}
		}
		return true;
	}

	static var _cornersA:Array<FlxPoint> = [for (i in 0...4) FlxPoint.get()];
	static var _cornersB:Array<FlxPoint> = [for (i in 0...4) FlxPoint.get()];
	static var _axes:Array<FlxPoint> = [for (i in 0...4) FlxPoint.get()];

	static function getOBBCorners(cx:Float, cy:Float, hx:Float, hy:Float, angle:Float, out:Array<FlxPoint>):Void {
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);

		out[0].set(-hx, -hy);
		out[1].set(hx, -hy);
		out[2].set(hx, hy);
		out[3].set(-hx, hy);

		for (i in 0...4) {
			var x = out[i].x;
			var y = out[i].y;
			out[i].set(x * cos - y * sin + cx, x * sin + y * cos + cy);
		}
	}

	static function getEdgeNormal(p1:FlxPoint, p2:FlxPoint, out:FlxPoint):FlxPoint {
		out.set(p2.x - p1.x, p2.y - p1.y);
		out.set(-out.y, out.x); // perpendicular
		out.normalize();
		return out;
	}

	static function overlapOnAxis(cornersA:Array<FlxPoint>, cornersB:Array<FlxPoint>, axis:FlxPoint):Bool {
		var minA = cornersA[0].dotProduct(axis);
		var maxA = minA;
		for (i in 1...4) {
			var d = cornersA[i].dotProduct(axis);
			if (d < minA)
				minA = d;
			if (d > maxA)
				maxA = d;
		}

		var minB = cornersB[0].dotProduct(axis);
		var maxB = minB;
		for (i in 1...4) {
			var d = cornersB[i].dotProduct(axis);
			if (d < minB)
				minB = d;
			if (d > maxB)
				maxB = d;
		}

		return !(maxA < minB || maxB < minA);
	}
}
