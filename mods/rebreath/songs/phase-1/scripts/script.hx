#if !android
return;
#end
import flixel.FlxObject;
import flixel.input.FlxInput;
import flixel.input.actions.FlxActionInputDigital;
import flixel.util.FlxSpriteUtil;
import funkin.options.PlayerSettings;

var hitboxes:FlxGroup;
var hint:FlxSprite;

function postCreate()
{
	camHUD.downscroll = true;

	hitboxes = new FlxGroup();
	hitboxes.camera = camHUD;
	add(hitboxes);

	hint = new FlxSprite();
	hint.makeGraphic(64, 64, 0x00FFFFFF);
	hint = FlxSpriteUtil.drawCircle(hint, -1, -1, -1, 0xABD6D6D6);
	hint.cameras = [camHUD];
	add(hint);

	for (i in 0...playerStrums.length)
	{
		final strum = playerStrums.members[i];

		var hitbox = new HitboxInput(0, 0, strum.width * 1.525, FlxG.height);
		hitbox.setup(i);
		hitbox.hint = hint;
		hitbox.x = strum.x + strum.width * .5 - hitbox.width * .5;
		hitboxes.add(hitbox);
	}
}

var tmr = 0.;

function update(elapsed)
{
	tmr += elapsed;

	if (FlxG.mouse.pressed)
	{
		tmr = 0;
	}

	hint.alpha = 1 - Math.min(1, tmr * 3);
	final pos = FlxG.mouse.getPositionInCameraView(camHUD);

	hint.x = pos.x - hint.width * .5;
	hint.y = FlxG.height - pos.y - hint.height * .5;

	pos.put();
}

function onPostStrumCreation(e)
{
	final strumScale = 0.5;
	final strumSize = Note.swagWidth;

	final strum = e.strum;
	if (strumLines.members[e.player].cpu)
	{
		strum.scale.set(strumScale, strumScale);
		strum.updateHitbox();

		strum.x = 50 + (strum.width) * strum.ID;
		strum.y = FlxG.height - strum.y - strum.height * 2;
	}
	else
	{
		strum.scale.set(1, 1);
		strum.updateHitbox();

		final factor = f(strum.ID - 1.5) * 1.125;

		strum.x = ((FlxG.width / 2) - strum.width / 2) + factor * strum.width;

		strum.scale.set(0.85, 0.85);
	}
}

function onStrumCreation(e)
{
	e.cancelAnimation();
}

function onPostNoteCreation(e)
{
	e.note.scale.set(e.note.strumLine.members[e.strumID].scale.x, e.note.strumLine.members[e.strumID].scale.y);
	e.note.updateHitbox();

	if (e.note.strumLine.cpu)
	{
		e.note.visible = false;
	}
}

function f(x:Float):Float
{
	if (x == 0)
		return 0;
	var abs = Math.abs(x);
	var offset = 0.5 + 0.8 * Math.max(abs - 1, 0);
	return FlxMath.signOf(x) * (abs + offset);
}

class HitboxInput extends FlxObject
{
	var input:FlxInput;

	var hint:FlxSprite;
	var hovering = false;
	var pressing = false;

	public function new(x, y, width, height)
	{
		super(x, y, width, height);
	}

	public function setup(ID)
	{
		this.ID = ID;

		var controls = PlayerSettings.solo.controls;
		input = new FlxInput();

		var triggerPressed = null;
		var triggerJPressed = null;
		var triggerJReleased = null;

		switch (ID)
		{
			case 0:
				triggerPressed = controls._noteLeft;
				triggerJPressed = controls._noteLeftP;
				triggerJReleased = controls._noteLeftR;
			case 1:
				triggerPressed = controls._noteDown;
				triggerJPressed = controls._noteDownP;
				triggerJReleased = controls._noteDownR;
			case 2:
				triggerPressed = controls._noteUp;
				triggerJPressed = controls._noteUpP;
				triggerJReleased = controls._noteUpR;
			case 3:
				triggerPressed = controls._noteRight;
				triggerJPressed = controls._noteRightP;
				triggerJReleased = controls._noteRightR;
		}
		triggerPressed.addInput(input, 1);
		triggerJPressed.addInput(input, 2);
		triggerJReleased.addInput(input, -1);
	}

	override public function update(elapsed)
	{
		super.update(elapsed);

		hovering = FlxG.overlap(this, hint);

		if (!pressing && hovering && FlxG.mouse.pressed)
		{
			input.press();

			pressing = true;
		}
		if (pressing && (!hovering || FlxG.mouse.released))
		{
			input.release();

			pressing = false;
		}

		input.update(elapsed);
	}
}
