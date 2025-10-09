import Sys;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText.FlxTextFormat;
import funkin.editors.charter.Charter;

var camPause = new FlxCamera();
var boxes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

var boxesData = [
	{
		x: 75,
		y: 100,
		i: 'box1'
	},
	{
		x: 77,
		y: 325,
		i: 'box2'
	}
	/*,
		{
			x: 420, 
			y: 100, 
			i: 'box3'
	}*/];

var scale = 1.9;
var nameTxt:FlxText;
var lvTxt:FlxText;
var hpTxt:FlxText;
var gTxt:FlxText;
var heart:FlxSprite;
var statsGrp:FlxTypedGroup<FlxText>;
var optionsGrp:FlxTypedGroup<FlxText>;
var curSelect = 0;

function destroy()
{
	FlxG.cameras.list.remove(camPause);
	camPause.destroy();
}

function create(ev)
{
	ev.cancel();

	if (PlayState.chartingMode)
		OPTIONS.push('Return To Chart');
	FlxG.cameras.add(camPause, false);
	camPause.bgColor = 0x98000000;
	cameras = [camPause];

	for (i in 0...boxesData.length)
	{
		var curData = boxesData[i];

		var box = new FlxSprite();
		box.loadGraphic(Paths.image('ut/pause/' + curData.i));
		box.scale.set(scale, scale);
		box.updateHitbox();
		box.setPosition(curData.x, curData.y);
		boxes.add(box);
	}
	add(boxes);

	nameTxt = new FlxText();
	nameTxt.setPosition(boxesData[0].x + 25, boxesData[0].y + 12);
	nameTxt.setFormat(Paths.font("determination-sans.ttf"), 54, 0xFFFFFF);
	nameTxt.text = Sys.environment()['USERNAME'];
	add(nameTxt);

	var i = 0;

	statsGrp = new FlxTypedGroup();
	add(statsGrp);

	for (text in [lvTxt, hpTxt, gTxt])
	{
		final curBox = boxesData[0];

		text = new FlxText();
		text.setPosition(curBox.x + 29, curBox.y + nameTxt.height + 13 + (i * 35));
		text.setFormat(Paths.font("undertale-hud.ttf"), 21, 0xFFFFFF);
		text.text = STATS_TEXTS[i];
		text.ID = i;
		statsGrp.add(text);

		i++;
	}

	optionsGrp = new FlxTypedGroup();
	add(optionsGrp);

	for (i in 0...OPTIONS.length)
	{
		final curBox = boxesData[1];

		text = new FlxText();
		text.setPosition(curBox.x + 85, curBox.y + 40 + (i * 62));
		text.setFormat(Paths.font("determination-sans.ttf"), 48, 0xFFFFFF);
		text.text = OPTIONS[i];
		text.ID = i;
		optionsGrp.add(text);
	}

	heart = new FlxSprite().loadGraphic(Paths.image('ut/soul'));
	heart.color = 0xFFFF00000;
	heart.scale.set(2.5, 2.5);
	heart.updateHitbox();
	add(heart);

	// best code ever
	updateItems(10000);
	updateHeart(10000);

	heart.x = -heart.width;
}

function update(e)
{
	updateSelection();

	for (item in statsGrp.members)
	{
		var text = STATS_TEXTS[item.ID];
		var type = STATS_TEXTS.indexOf(text);

		switch (type)
		{
			// LEVEL
			case 0:
				item.text = text + '69';
			// HP
			case 1:
				item.text = text + Std.string(Std.int(game.health * 10)) + '/20';
			// GOLD
			case 2:
				item.text = text + '0';
		}
	}
}

function updateSelection()
{
	if (controls.ACCEPT)
	{
		select();
	}
	var up = controls.UP_P;
	var down = controls.DOWN_P;

	curSelect = FlxMath.wrap(curSelect + ((up || down) ? (down ? 1 : -1) : 0), 0, OPTIONS.length - 1);

	updateItems();
	updateHeart();
}

function updateHeart(?mult)
{
	if (mult == null)
		mult = 1;

	final curBox = boxesData[1];
	final curItem = optionsGrp.members[curSelect];

	final curX = curBox.x + 32;
	final curY = curItem.y + curItem.fieldHeight / 2 - heart.height / 2;

	final deltaX = CoolUtil.fpsLerp(heart.x, curX, Math.min(1, 0.125 * ITEM_UPDATE_SPEED * mult));
	final deltaY = CoolUtil.fpsLerp(heart.y, curY, Math.min(1, 0.125 * ITEM_UPDATE_SPEED * mult));

	heart.setPosition(deltaX, deltaY);
}

function updateItems(?mult)
{
	if (mult == null)
		mult = 1;
	optionsGrp.forEach(item ->
	{
		final curBox = boxesData[1];
		final selected = item.ID == curSelect;
		final curX = curBox.x + ITEM_SELECT_OFF_X + (selected ? (85 - ITEM_SELECT_OFF_X) : 0);

		final deltaX = CoolUtil.fpsLerp(item.x, curX, Math.min(1, 0.125 * ITEM_UPDATE_SPEED * mult));

		item.setPosition(deltaX, curBox.y + 40 + (item.ID * 62));
		item.color = FlxColor.interpolate(item.color, selected ? 0xFFFFFF00 : 0xFFFFFFFF, Math.min(1, 60 * FlxG.elapsed * 0.2 * mult));
	});
}

function select()
{
	switch (optionsGrp.members[curSelect].text.toLowerCase())
	{
		case 'resume':
			close();
		case 'reset':
			parentDisabler.reset();
			game.registerSmoothTransition();
			FlxG.resetState();
		case 'exit':
			FlxG.switchState(PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
		case 'return to chart':
			FlxG.switchState(new Charter(PlayState.SONG.meta.name, PlayState.difficulty, false));
	}
}

var ITEM_UPDATE_SPEED = 1.2;
var ITEM_SELECT_OFF_X = 45;
var OPTIONS = ['Resume', 'Reset', 'Exit'];
var STATS_TEXTS = ['lv   ', 'hp   ', 'g     '];
