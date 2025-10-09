//
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxAngle;
import flixel.util.FlxDirectionFlags;
import ut.FightBox;
import ut.Soul;

var box:FightBox;
var soul:Soul;
var infoTxt:FlxText;

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

	box.guest = soul;

	infoTxt = new FlxText(0, 0, 1000, "");
	infoTxt.size = 32;
	infoTxt.alignment = 'center';
	add(infoTxt);

	// blaster shit
	bHead = new FlxSprite();
	bHead.loadGraphic(Paths.image('ut/blaster/head0'));
	bHead.scale.scale(4);
	bHead.updateHitbox();
	add(bHead);

	bBlast = new FlxSprite();
	bBlast.loadGraphic(Paths.image('ut/blaster/beam'));
	bBlast.scale.set(4, 4);
	bBlast.updateHitbox();
	bBlast.alpha = 0.0001;
	add(bBlast);
}

// blaster shit
var bHead:FlxSprite;
var bBlast:FlxSprite;
var bHeadState:Int = 0;
var bAttackState:String = "";
var _bLHeadState:Int = 0;
var _bLAttackState:String = "";

// time controllers
var bTimeline:Float = 0;
var _bLTimeline:Float = -1;
var bTimeRunning:Bool = false;

// timers
// intro duration (works as speed ig?)
var bIntroDur:Float = 0.8;

// blaster afk
var bAwaitDur:Float = 0.05;

// blaster mouth opening and squish animation duration
var bMouthOpeningDur:Float = 0.25;

// blaster blasting time before going away
var bAttackDur:Float = 0;

// this is not duration, but speed
var bLeaveSpeed:Float = 1;

// attack params
var bInitPos = FlxPoint.get(0, 0);
var bInitAngle:Float = -360;
var bAttackPos = FlxPoint.get(500, 500);
var bAttackAngle:Float = -50;

function update(elapsed) {
	// blaster shit
	// TIME LINE
	if (FlxG.keys.justPressed.SPACE)
		bTimeRunning = !bTimeRunning;
	if (FlxG.keys.pressed.N) {
		bTimeRunning = false;
		bTimeline -= elapsed;
	}
	if (FlxG.keys.pressed.M) {
		bTimeRunning = false;
		bTimeline += elapsed;
	}
	if (bTimeRunning)
		bTimeline += elapsed;

	bTimeline = Math.max(0, bTimeline);

	// ACTUAL MOTION
	if (bTimeline < bIntroDur) {
		bAttackState = 'Intro';

		final ratio = FlxEase.expoOut(bTimeline / bIntroDur);

		bHead.setPosition(FlxMath.lerp(bInitPos.x, bAttackPos.x, ratio), FlxMath.lerp(bInitPos.y, bAttackPos.y, ratio));
		bHead.angle = FlxMath.lerp(bInitAngle, bAttackAngle, ratio);
		bBlast.alpha = 0.0001;
		bHeadState = 0;
		bBlast.scale.y = 0;
		bBlast.alpha = 0.0001;
		bHead.scale.x = 4;
	} else if (bTimeline < bIntroDur + bAwaitDur) {
		bAttackState = 'Await';
		bHead.setPosition(bAttackPos.x, bAttackPos.y);
		bHead.angle = bAttackAngle;
		bBlast.alpha = 0.0001;
		bHeadState = 0;
		bHead.scale.x = 4;
		bBlast.scale.y = 0;
	} else if (bTimeline < bIntroDur + bAwaitDur + bMouthOpeningDur) {
		bAttackState = 'Preparing';
		bHead.setPosition(bAttackPos.x, bAttackPos.y);
		bHead.angle = bAttackAngle;
		final ratio = (bTimeline - (bIntroDur + bAwaitDur)) / bMouthOpeningDur;
		final sineFactor = roundedExpDip(ratio);

		bHead.scale.x = 4 - sineFactor * .5;
		bBlast.alpha = 1;
		bHeadState = FlxEase.quartInOut(Math.min(1, ratio)) * 3;

		if (ratio >= 0.85) {
			bAttackState = 'Opening';
			bBlast.scale.y = 1;
			bBlast.alpha = 0.2;
		} else {
			bBlast.scale.y = 0;
			bBlast.alpha = 0.0001;
		}
	} else {
		final timeElap = (bTimeline - (bIntroDur + bAwaitDur + bMouthOpeningDur)) * bLeaveSpeed;
		final leaveElapsed = Math.max(0, timeElap - bAttackDur);
		final builderElaped = Math.pow(leaveElapsed, 4) * 600;
		final sin = FlxMath.fastSin(bAttackAngle * Math.PI / 180);
		final cos = FlxMath.fastCos(bAttackAngle * Math.PI / 180);
		bAttackState = leaveElapsed == 0 ? 'Attacking' : 'Attack Leave';

		bHead.setPosition(bAttackPos.x + builderElaped * -cos, bAttackPos.y + builderElaped * -sin);
		bHead.angle = bAttackAngle;

		final bounceSine = bAttackDur == 0 ? 0.8 : Math.abs(Math.cos((timeElap - .25) * 1.25 * Math.PI));
		final fade = 1 - FlxMath.bound(Math.pow(leaveElapsed, 4), 0, 1);

		bHead.scale.x = 3.76 + FlxEase.quintOut(Math.min(1, timeElap * 4)) * 0.25;
		bHeadState = 4 + Math.min(1, timeElap * 40) - 2 * FlxMath.bound((1 - fade) * 2, 0, 1);
		bBlast.scale.y = (2 + FlxEase.quintOut(Math.min(1, timeElap * 2.5)) * 2 - 0.7 + bounceSine * 1.5) * fade;
		bBlast.alpha = (0.3 + FlxEase.quintOut(Math.min(1, timeElap * 5)) * 0.7 * (0.75 + bounceSine * .25)) * fade;
	}
	bHead.angle = bHead.angle - 90;
	bBlast.angle = bHead.angle + 90;

	var headMidpoint = bHead.getMidpoint();
	var sin = FlxMath.fastSin(bBlast.angle * Math.PI / 180);
	var cos = FlxMath.fastCos(bBlast.angle * Math.PI / 180);
	var offset = 22 * bBlast.scale.x;

	bBlast.updateHitbox();
	bBlast.x = headMidpoint.x + cos * (bBlast.width * .5 + offset) - (bBlast.width * .5);
	bBlast.y = headMidpoint.y + sin * (bBlast.width * .5 + offset) - (bBlast.height * .5);

	headMidpoint.put();

	if (_bLAttackState != bAttackState) {
		if (bAttackState == 'Intro') {
			FlxG.sound.play(Paths.sound('ut/blaster_start'));
		} else if (bAttackState == 'Opening')
			FlxG.sound.play(Paths.sound('ut/blaster_shoot'));
	}
	if (_bLHeadState != bHeadState) {
		bHead.loadGraphic(Paths.image('ut/blaster/head' + Std.string(Std.int(bHeadState))));
		bHead.updateHitbox();
	}
	_bLAttackState = bAttackState;
	_bLHeadState = bHeadState;
	// no blaster shit

	if (FlxG.keys.pressed.R)
		box.angle += 30 * elapsed;

	if (FlxG.keys.pressed.U)
		soul.angle += 90 * elapsed;

	if (soul.angle >= 360)
		soul.angle = 0;

	soul.updateMovement(elapsed);
	box.updateCollision();

	if (FlxG.keys.justPressed.B)
		soul.mode = soul.mode == 'blue' ? 'red' : 'blue';

	infoTxt.text = 'Box Angle: '
		+ box.angle
		+ '\nSoul Angle: '
		+ soul.angle
		+ '\nBlaster Timer: '
		+ bTimeline
		+ '\nBlaster State: '
		+ bAttackState;
	infoTxt.screenCenter(0x01);
	infoTxt.y = 0;
}

function expState(t:Float):Float {
	var result = 0;
	if (t < 0.5)
		result = FlxEase.circOut(t * 2);
	else if (t >= 0.5)
		result = FlxEase.circOut(1 - (t - 0.5) * 2);

	return result;
}

function roundedExpDip(t:Float):Float {
	var result = 0;
	if (t < 0.5)
		result = FlxEase.circOut(t * 2);
	else if (t >= 0.5)
		result = FlxEase.circOut(1 - (t - 0.5) * 1.5);

	return result;
}
