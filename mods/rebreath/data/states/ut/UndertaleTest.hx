//
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import ut.Blaster;
import ut.FightBox;
import ut.Platform;
import ut.Soul;

var box:FightBox;
var soul:Soul;
var blaster:Blaster;
var infoTxt:FlxText;
var platform:FlxSprite;

function create() {
	camera.bgColor = 0xFF6D6D6D;

	box = new FightBox();
	box.boxWidth = 350;
	box.boxHeight = 400;
	box.thickness = 20;
	box.update(0);
	box.screenCenter();
	add(box);

	soul = new Soul();
	soul.screenCenter();
	soul.size = 2.5;
	add(soul);

	platform = new Platform(0, 0, 100, 20);
	platform.thickness = 6;
	platform.allowCollisions = 0x0100;
	platform.screenCenter();
	platform.immovable = true;
	platform.y += 30;
	add(platform);

	box.guest = soul;

	infoTxt = new FlxText(0, 0, 1000, "");
	infoTxt.size = 32;
	infoTxt.alignment = 'center';
	add(infoTxt);

	blaster = new Blaster();
	blaster.setup({
		initialPosition: FlxPoint.get(-500, -500),
		initialAngle: -360,

		attackPosition: FlxPoint.get(100, 100),
		attackAngle: 45,
		introDuration: Float = 0.8,

		awaitDuration: Float = 0.05,
		prepareDuration: Float = 0.25,
		holdDuration: Float = 0,
		builderSpeed: Float = 1,

		scaleX: 1,
		scaleY: 0.5
	});
	add(blaster);

	blaster.start();
}

var changingTime:Bool = false;

function update(elapsed) {
	// blaster shit
	// TIME LINE
	if (FlxG.keys.justPressed.SPACE)
		blaster.dirtyTimeline = !blaster.dirtyTimeline;
	if (FlxG.keys.pressed.N) {
		blaster.timePosition -= elapsed;
	}
	if (FlxG.keys.pressed.M) {
		blaster.timePosition += elapsed;
	}
	if (blaster.bTimeRunning)
		blaster.timePosition += elapsed;

	blaster.timePosition = Math.max(blaster.timePosition);

	if (FlxG.keys.pressed.R)
		box.angle += 30 * elapsed;

	if (FlxG.keys.pressed.U)
		soul.angle += 90 * elapsed;

	if (soul.angle >= 360)
		soul.angle = 0;

	soul.updateMovement(elapsed);
	var grounded = false;
	FlxG.collide(soul, platform, () -> {
		grounded = true;
	});
	box.updateCollision();
	if (grounded)
		soul.grounded = true;

	if (FlxG.keys.justPressed.B)
		soul.mode = soul.mode == 'blue' ? 'red' : 'blue';

	infoTxt.text = 'Box Angle: ' + box.angle + '\nSoul Angle: ' + soul.angle + '\nBlaster Timer: ' + blaster.timePosition + '\nBlaster State: '
		+ blaster.attackState;
	infoTxt.screenCenter(0x01);
	infoTxt.y = 0;
}
