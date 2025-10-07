package ut.core.behavior;

import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.backend.system.Controls;
import ut.Soul;

class SoulBehavior implements IFlxDestroyable
{
	public var host:Soul;
	public var controller:Controls;

	public var speed:Float = 1;

	public var PIXELS_PER_FRAME(get, never):Float;
	public var IS_GROUNDED(get, never):Bool;

	public var direction:FlxPoint = FlxPoint.get();

	private var normalDir:FlxPoint = FlxPoint.get();
	private var lastLeftTime:Int = -1;
	private var lastRightTime:Int = -1;
	private var lastUpTime:Int = -1;
	private var lastDownTime:Int = -1;
	private var ticks:Int = 0;

	function get_PIXELS_PER_FRAME()
		return Constants.SOUL_MOVEMENT_PIXELS_PER_FRAME * speed;

	function get_IS_GROUNDED()
		return host.grounded;

	public function new(host:Soul, controller:Controls):Void
	{
		this.host = host;
		this.controller = controller;
	}

	public function setup()
	{
	}

	public function update(elapsed:Float):SoulBehaviorOutput
		return
		{
		};

	public function destroy()
	{
		normalDir.put();
		direction.put();
	}
}

@:publicFields
@:structInit
final class SoulBehaviorOutput
{
	var deltaX:Float = 0;
	var deltaY:Float = 0;

	public function new()
	{
	}
}
