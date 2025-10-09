//
// dirty code, but im tired af to clean it
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import funkin.backend.assets.Paths;
import funkin.menus.MainMenuState;
import openfl.filters.GlowFilter;

var bg:FlxSprite;
var items:FlxTypedGroup<FlxSkewedSprite> = new FlxTypedGroup();
var selection = 0;
var lastSelection = -1;
var uText:FlxText;
var lArrow:FlxText;
var rArrow:FlxText;

function create() {
	camera.pixelPerfectRender = true;
	camera.antialiasing = false;

	bg = new FlxSprite().loadGraphic(Paths.image('ut/play/bg'));
	bg.setGraphicSize(FlxG.width, FlxG.height);
	bg.updateHitbox();
	bg.screenCenter();
	bg.scale.x *= 1.05;
	bg.scale.y *= 1.05;
	add(bg);

	for (i in 0...3) {
		var newItem = new FlxSkewedSprite();
		newItem.loadGraphic(Paths.image('ut/play/ops/main'));
		newItem.scale.scale(2);
		newItem.ID = i;
		newItem.scrollFactor.set(2, 2);
		items.add(newItem);
	}
	add(items);

	uText = new FlxText(0, 50);
	uText.setFormat(Paths.font('pixelmax.ttf'), 84);
	uText.text = 'Select the Chapter';
	uText.screenCenter(FlxAxes.X);
	add(uText);

	var space = 60;

	rArrow = new FlxText();
	rArrow.setFormat(Paths.font('pixelmax.ttf'), 128);
	rArrow.text = '>';
	rArrow.screenCenter(FlxAxes.Y);
	rArrow.x = FlxG.width - space - rArrow.width;
	add(rArrow);

	lArrow = new FlxText();
	lArrow.setFormat(Paths.font('pixelmax.ttf'), 128);
	lArrow.text = '<';
	lArrow.screenCenter(FlxAxes.Y);
	lArrow.x = space;
	add(lArrow);

	update(0.001);
	selectionLerp = 1;
}

var depth = 0.2;
var selectionLerp = 1;
var bakedLerp = 0;
var camX = 0;
var camY = 0;
var mouseDelay = 0;
var arrowLerp = 0.;

function isMouseInScreen() {
	return FlxG.mouse.x > 0 && FlxG.mouse.x < FlxG.width && FlxG.mouse.y > 0 && FlxG.mouse.y < FlxG.height;
}

function update(elapsed) {
	uText.scale.x = Math.floor((1 + Math.sin(curBeatFloat * Math.PI) * 0.025) * 64) / 64;
	uText.scale.y = Math.floor((1 + Math.cos(curBeatFloat * Math.PI) * 0.025) * 64) / 64;

	camera.scroll.x = CoolUtil.fpsLerp(camera.scroll.x, camX, 0.08);
	camera.scroll.y = CoolUtil.fpsLerp(camera.scroll.y, camY, 0.08);

	camX = FlxG.mouse.screenX * 0.0125;
	camY = FlxG.mouse.screenY * 0.0125;

	if (controls.LEFT_P)
		selection -= 1;
	if (controls.RIGHT_P)
		selection += 1;

	if (selection != lastSelection)
		onMouse = false;

	if (controls.BACK)
		FlxG.switchState(new MainMenuState());

	if (FlxG.mouse.justMoved)
		onMouse = true;

	mouseDelay += elapsed * 4;

	var insideShit = Math.abs(FlxG.mouse.x - FlxG.width / 2) > 500 && Math.abs(FlxG.mouse.y - FlxG.height / 2) < 275;

	if (controls.ACCEPT || (FlxG.mouse.justReleased && !insideShit)) {
		PlayState.loadSong('phase-1', 'normal', false, false);
		FlxG.switchState(new PlayState());
	}
	if (onMouse && isMouseInScreen() && insideShit) {
		var sign = FlxMath.signOf(FlxG.mouse.x - FlxG.width / 2);
		var arrow = (sign < 0 ? lArrow : rArrow);

		if (mouseDelay >= 1.5) {
			selection += sign;
			mouseDelay = 0;

			arrow.color = 0xFFFFFF00;
			arrow.scale.scale(1.2);
			arrowLerp = 0;
		}
	} else {
		lArrow.color = rArrow.color = 0xFFFFFFFF;
	}
	arrowLerp = CoolUtil.fpsLerp(arrowLerp, 1, 0.0125);

	final bakedArrowLerp = Math.round(arrowLerp * 4) / 4;
	lArrow.scale.x = lArrow.scale.y = FlxMath.lerp(lArrow.scale.x, 1, bakedArrowLerp);
	rArrow.scale.x = rArrow.scale.y = FlxMath.lerp(rArrow.scale.x, 1, bakedArrowLerp);

	selection = FlxMath.wrap(selection, 0, items.length - 1);
	if (lastSelection != selection)
		selectionLerp = 0;

	items.forEach(item -> {
		if (lastSelection != selection)
			item.loadGraphic(Paths.image('ut/play/ops/main' + (selection == item.ID ? 'S' : '')));

		selectionLerp = FlxMath.lerp(selectionLerp, 1, .0025 * 60 * FlxG.elapsed);
		bakedLerp = Math.floor(selectionLerp * 24) / 24;

		var angle = (Math.PI / items.length) * (item.ID - selection) * 2;
		var sin = Math.sin(angle);
		var cos = -Math.cos(angle);

		var motion = Math.cos((FlxG.game.ticks * 0.00025 + (item.ID * 0.5)) * Math.PI);

		var originX = FlxG.width / 2;
		var originY = FlxG.height / 2;

		var projectedX = originX + sin * 350;
		var projectedY = originY + cos * 10 + motion * 5;

		item.x = FlxMath.lerp(item.x, projectedX - item.width / 2, bakedLerp);
		item.y = FlxMath.lerp(item.y, projectedY - item.height / 2, bakedLerp);
		item.scale.x = item.scale.y = FlxMath.lerp(item.scale.x, 2.6 - cos * depth, bakedLerp);
		item._z = FlxMath.lerp(item._z, cos * depth * 100, bakedLerp);
		item.alpha = FlxMath.lerp(item.alpha, 1 - cos * 0.7, bakedLerp);
	});
	items.sort((a, b) -> a._z - b._z);

	lastSelection = selection;
}
