package ut.core.behavior.list;

import flixel.math.FlxPoint;
import ut.core.behavior.SoulBehavior;

class DefaultMode extends SoulBehavior
{
	override public function update(elapsed:Float):SoulBehaviorOutput
	{
		var output:SoulBehaviorOutput = {};
		var directions = getInput();

		final mult = host.adaptiveSpeed ? host.size : 1;
		output.deltaX += directions.x * PIXELS_PER_FRAME * 30 * elapsed * mult;
		output.deltaY += directions.y * PIXELS_PER_FRAME * 30 * elapsed * mult;

		return output;
	}

	private function getInput()
	{
		final tick0 = ticks == 0;

		ticks++;

		if ((tick0 && controller.NOTE_LEFT) || controller.NOTE_LEFT_P)
			lastLeftTime = ticks;
		if ((tick0 && controller.NOTE_RIGHT) || controller.NOTE_RIGHT_P)
			lastRightTime = ticks;
		if ((tick0 && controller.NOTE_UP) || controller.NOTE_UP_P)
			lastUpTime = ticks;
		if ((tick0 && controller.NOTE_DOWN) || controller.NOTE_DOWN_P)
			lastDownTime = ticks;

		if (controller.NOTE_LEFT_R)
			lastLeftTime = -1;
		if (controller.NOTE_RIGHT_R)
			lastRightTime = -1;
		if (controller.NOTE_UP_R)
			lastUpTime = -1;
		if (controller.NOTE_DOWN_R)
			lastDownTime = -1;

		if (lastLeftTime > lastRightTime)
			direction.x = -1;
		else if (lastRightTime > lastLeftTime)
			direction.x = 1;
		else
			direction.x = 0;

		if (lastUpTime > lastDownTime)
			direction.y = -1;
		else if (lastDownTime > lastUpTime)
			direction.y = 1;
		else
			direction.y = 0;

		var dx = direction.x;
		var dy = direction.y;
		if (dx != 0 && dy != 0)
		{
			dx *= 0.7071;
			dy *= 0.7071;
		}

		normalDir.set(dx, dy);
		return normalDir;
	}

	override public function setup()
	{
		super.setup();

		host.color = 0xFFFF0000;
	}
}
