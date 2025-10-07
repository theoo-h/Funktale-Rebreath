package ut.core.util;

class ControllerUtil
{
	private static var ROTATED_KEYS(default, never):Array<ControllerKeys> = [
		{
			LEFT: "_noteLeft",
			RIGHT: "_noteRight",
			UP: "_noteUp",
			DOWN: "_noteDown"
		},
		{
			LEFT: "_noteDown",
			RIGHT: "_noteUp",
			UP: "_noteRight",
			DOWN: "_noteLeft"
		},
		{
			LEFT: "_noteRight",
			RIGHT: "_noteLeft",
			UP: "_noteDown",
			DOWN: "_noteUp"
		},
		{
			LEFT: "_noteUp",
			RIGHT: "_noteDown",
			UP: "_noteLeft",
			DOWN: "_noteRight"
		}
	];

	inline public static function getRotatedKeys(groundAngle:Float):ControllerKeys
		return ROTATED_KEYS[Math.round((groundAngle % 360) / 90) % 4];
}

typedef ControllerKeys =
{
	var LEFT:String;
	var RIGHT:String;
	var UP:String;
	var DOWN:String;
}
