package ut.core.behavior.list;

import flixel.math.FlxAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import funkin.backend.system.Controls;
import funkin.backend.utils.ControlsUtil;
import ut.core.behavior.SoulBehavior;
import ut.core.util.ControllerUtil;

/**
 * Jump (blue) mode controller used in Undertale's Sans and Papyrus fights.
 * 90% Accurate Physics.
 * 
 * Based on this Post.
 * https://www.reddit.com/r/Underminers/comments/3yq1nn/physics_for_blue_soul/
 */
class JumpMode extends DefaultMode
{
	var vSpeed:Float = 0;
	var didJump:Bool = false;
	var didCut:Bool = false;

	public var gravityMult:Float = 1;

	var lastHostY:Float = 0.;
	var tick0 = true;

	static final JP_TAG:String = '-press';
	static final R_TAG:String = '-release';

	inline private function getPressed(name:String)
		@:privateAccess return ControlsUtil.checkControl(controller, name);

	inline private function getJustPressed(name:String)
		@:privateAccess return (tick0 && getPressed(name)) || ControlsUtil.checkControl(controller, name + 'P');

	inline private function getJustReleased(name:String)
		@:privateAccess return ControlsUtil.checkControl(controller, name + 'R');

	override public function update(elapsed:Float):SoulBehaviorOutput
	{
		var output:SoulBehaviorOutput = {};
		final rotatedKeys = ControllerUtil.getRotatedKeys(host.angle);

		@:privateAccess
		var sin = FlxMath.fastSin(-host.angle * FlxAngle.TO_RAD);
		@:privateAccess
		var cos = FlxMath.fastCos(-host.angle * FlxAngle.TO_RAD);

		tick0 = ticks == 0;

		ticks++;

		// actualizamos tiempos de presionado
		if (getJustPressed(rotatedKeys.LEFT))
			lastLeftTime = ticks;
		if (getJustPressed(rotatedKeys.RIGHT))
			lastRightTime = ticks;

		// limpiamos cuando se sueltan
		if (getJustReleased(rotatedKeys.LEFT))
			lastLeftTime = -1;
		if (getJustReleased(rotatedKeys.RIGHT))
			lastRightTime = -1;

		// decidimos dirección con prioridad al último input válido
		if (lastLeftTime > lastRightTime)
			direction.x = -1;
		else if (lastRightTime > lastLeftTime)
			direction.x = 1;
		else
			direction.x = 0;

		// vertical reset
		if (!getPressed(rotatedKeys.UP) && direction.y == -1)
			direction.y = 0;

		// vertical input
		if (getJustPressed(rotatedKeys.UP))
			direction.y = -1;

		var dx = direction.x;
		var dy = direction.y;
		if (dx != 0 && dy != 0)
			dx *= 0.7071;

		normalDir.set(dx, dy);

		if (IS_GROUNDED)
		{
			didJump = false;
			didCut = false;
			vSpeed = 0;

			if (getPressed(rotatedKeys.UP))
			{
				vSpeed = -6;
				didJump = true;
			}
		}

		if (didJump && !getPressed(rotatedKeys.UP) && vSpeed < -1 && !didCut)
		{
			didCut = true;
			vSpeed = -1;
		}

		final frameSync = 30 * elapsed;

		// gravity
		vSpeed += getFixedGravity(vSpeed) * gravityMult * frameSync;

		// max fall speed
		if (vSpeed > 20)
			vSpeed = 20;

		final mult = host.adaptiveSpeed ? host.size : 1;
		var deltaX = normalDir.x * PIXELS_PER_FRAME * frameSync * mult;
		var deltaY = vSpeed * frameSync * mult;
		output.deltaX += deltaY * sin + deltaX * cos;
		output.deltaY += deltaX * sin + deltaY * cos;

		return output;
	}

	override public function setup()
	{
		super.setup();

		host.color = 0xFF0000FF;
	}

	// multiplied by 0.9 so it falls slowly cuz i feel more accurate like that
	inline function getFixedGravity(velocity:Float):Float
		return (if (velocity <= -4) .2; else if (velocity <= -1) .5; else if (velocity <= .5) .2; else if (velocity < 8) .6; else 0) * .9;
}
