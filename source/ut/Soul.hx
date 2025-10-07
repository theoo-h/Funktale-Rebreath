package ut;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import funkin.backend.system.Controls;
import funkin.options.PlayerSettings;
import ut.core.behavior.SoulBehavior;
import ut.core.behavior.list.*;
import ut.core.interfaces.ICollidable;
import ut.core.util.OBBCollision;

using StringTools;

enum abstract SoulMode(String)
{
	public var NORMAL = 'normal';
	public var BLUE = 'blue';
}

class Soul extends FlxSprite implements ICollidable
{
	public var behavior:SoulBehavior;
	public var controller:Controls;

	public var host:FightBox;

	public var grounded:Bool = false;
	public var playable:Bool = true;

	public var mode(default, set):SoulMode = NORMAL;

	public var quiet(get, never):Bool;

	function get_quiet():Bool
	{
		return _quiet;
	}

	public var size(default, set):Float = 1;
	public var adaptiveSpeed:Bool = true;

	public var hitbox:FlxObject;
	public var collidable:Bool;

	public var overlay:FlxSprite;
	public var overlayAnimation:Bool = false;
	public var overlayDuration:Float = 0.5;
	public var overlayTmr:Float = 0;

	public function set_size(size)
	{
		scale.set(size, size);
		updateHitbox();

		return this.size = size;
	}

	function set_mode(val:SoulMode):SoulMode
	{
		if (behavior != null)
			behavior.destroy();
		switch (val)
		{
			case BLUE:
				behavior = new JumpMode(this, controller);
			default:
				behavior = new DefaultMode(this, controller);
		}
		behavior.setup();

		overlayAnimation = true;
		overlayTmr = 0;
		FlxG.sound.play(Paths.sound("ut/ping"));

		return mode = val;
	}

	public function new(?controller:Controls)
	{
		super();

		if (controller == null)
			controller = PlayerSettings.solo.controls;

		loadGraphic(Paths.image('ut/soul'));
		updateHitbox();

		pixelPerfectRender = true;
		moves = false;

		this.controller = controller;
		this.mode = NORMAL;

		collidable = true;

		hitbox = new FlxObject();

		overlay = new FlxSprite();
		overlay.loadGraphic(Paths.image('ut/soul'));
		overlay.pixelPerfectRender = true;
		overlay.moves = false;
	}

	public function boxCenter(?box:FightBox)
	{
		if (box == null)
			box = this.host;
		setPosition(box.x + box.width * .5 - width * .5, box.y + box.height * .5 - height * .5);
	}

	var lastX = -1.;
	var lastY = -1.;
	var _quiet = true;

	public function resolveCollision(object:ICollidable):Bool
	{
		return OBBCollision.check(this, object.hitbox) && object.collidable;
	}

	public function updateMovement(elapsed:Float)
	{
		var deltaBh = behavior.update(elapsed);

		x += deltaBh.deltaX;
		y += deltaBh.deltaY;

		if (lastX != x || lastY != y)
			_quiet = false;
		else
			_quiet = true;

		lastX = x;
		lastY = y;

		collidable = !_quiet;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		hitbox.setSize(width * .5, height * .5);
		hitbox.setPosition(x + (width - hitbox.width) * .5, y + (height - hitbox.height) * .5);

		if (overlayAnimation)
		{
			overlayTmr += elapsed;

			final ratio = overlayTmr / overlayDuration;
			overlay.setGraphicSize(Std.int(this.width * this.scale.x), Std.int(this.height * this.scale.y));
			overlay.updateHitbox();

			overlay.setPosition(this.x + 0.5 * (this.width - overlay.width), this.y + 0.5 * (this.height - overlay.height));
			overlay.color = this.color;

			overlay.scale.scale(1 + ratio);
			overlay.alpha = 1 - ratio;
			overlay.cameras = this.cameras;

			if (overlayTmr >= overlayDuration)
			{
				overlayTmr = 0;
				overlayAnimation = false;
			}

			overlay.update(elapsed);
		}
	}

	override function draw()
	{
		super.draw();

		if (overlayAnimation)
			overlay.draw();
	}
}
