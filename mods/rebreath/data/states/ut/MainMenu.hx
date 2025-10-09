// is this a good code ?
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxGradient;
import funkin.backend.MusicBeatState;
import funkin.backend.scripting.ModState;
import funkin.backend.shaders.CustomShader;
import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.FlxInterpolateColor;
import funkin.editors.EditorPicker;
import funkin.editors.ui.UIState;
import funkin.menus.ModSwitchMenu;
import funkin.menus.credits.CreditsMain;
import funkin.options.OptionsMenu;

static var loaded = false;
var sans:FlxSprite;
var logo:FlxSprite;
var gradient:FlxSprite;
var itemsGrp:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
var optionsB:FlxButton;
var particles:FlxTypedGroup<FlxSprite>;
var itemList:Array<String> = ['start', 'credits', 'gallery'];
var await;
var counter = 0;
var transP = 1;
var tmr = 0.;
var heatShader:CustomShader;
var heatShader2:CustomShader;
var sparkles:CustomShader;
var bloomShader:CustomShader;
var lensBlur:CustomShader;
var cameraUI;
var blackT:FlxTween;
var lastSelected = -1;
var curSelect = 0;
var camX = 0;
var camY = 0;
var blur = 0.5;
var actived = false;
var bloomIntensity = 0;
var choised = false;

function postCreate()
{
	if (!loaded)
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		MusicBeatState.skipTransIn = true;
	}

	trace('REBREATH MENU LOADED');

	cameraUI = new FlxCamera();
	cameraUI.bgColor = 0;
	FlxG.cameras.add(cameraUI, true);

	lensBlur = new CustomShader('lensBlur');
	lensBlur.iAmount = blur;

	gradient = new FlxSprite();
	gradient.loadGraphic(FlxGradient.createGradientBitmapData(FlxG.width, FlxG.height, [0xFF000000, 0xFF000000, 0xFF52120D]));
	gradient.scrollFactor.set(0.3, 0.3);
	gradient.cameras = [camera];
	gradient.shader = heatShader = new CustomShader('heat');
	gradient.alpha = 0.5;
	add(gradient);

	bg = new FlxSprite();
	bg.makeGraphic(FlxG.width, FlxG.height, 0);
	bg.cameras = [camera];
	bg.shader = sparkles = new CustomShader('fire');
	add(bg);

	particles = new FlxTypedGroup(25);
	add(particles);

	var lastY = BASE_Y;

	for (i in 0...itemList.length)
	{
		var col = 0;
		var cell = i;

		var item = new FlxSprite();
		item.loadGraphic(Paths.image('ut/menu/' + itemList[i]));
		item.scale.set(ITEM_SCALE, ITEM_SCALE);
		item.updateHitbox();
		item.setPosition(BASE_X + col * SPACING_X - item.width / 2, lastY + SPACING_Y);
		item.ID = i;
		item.color = 0xFFFFFFFF;
		item.camera = cameraUI;
		itemsGrp.add(item);

		lastY = item.y + item.height;
	}

	add(itemsGrp);

	optionsB = new FlxButton();
	optionsB.loadGraphic(Paths.image('ut/menu/settings'));
	optionsB.scale.set(0.25, 0.25);
	optionsB.updateHitbox();
	optionsB.x = FlxG.width - optionsB.width - 30;
	optionsB.y = 30;
	optionsB.scrollFactor.set(1, 1);
	optionsB.color = 0xFFB6B6B6;
	optionsB.camera = cameraUI;
	add(optionsB);

	sans = new FlxSprite();
	sans.loadGraphic(Paths.image('ut/menu/sans'));
	sans.scale.set(1.1, 1.1);
	sans.updateHitbox();
	sans.camera = cameraUI;
	add(sans);

	logo = new FlxSprite(0, LOGO_BASE_Y);
	logo.frames = Paths.getFrames('ut/menu/logo');
	logo.scale.set(LOGO_SCALE, LOGO_SCALE);
	logo.updateHitbox();
	logo.screenCenter(FlxAxes.X);
	logo.animation.addByPrefix('loop', 'logo instance 1');
	logo.camera = cameraUI;
	add(logo);

	FlxTween.num(-sTwnAmp, sTwnAmp, Conductor.stepCrochet / 500, {
		type: 4,
		ease: function(t)
		{
			return Math.floor(t * sTwnDiv) / sTwnDiv;
		}
	}, (f) ->
		{
			sFOff = f;
		});
	bloomShader = new CustomShader('bloom');
	heatShader2 = new CustomShader('heat2');

	camera.addShader(bloomShader);
	camera.addShader(heatShader2);
	camera.addShader(lensBlur);

	cameraUI.addShader(heatShader2);
	cameraUI.addShader(bloomShader);

	actived = true;
	update(0);
	actived = false;

	if (!loaded)
	{
		CoolUtil.playMenuSong();
		FlxG.sound.music.pause();
	}
	else
	{
		if (FlxG.sound.music == null)
			CoolUtil.playMenuSong();
	}

	await = Conductor.crochet / 175;

	if (!loaded)
	{
		var black = new FlxSprite();
		black.makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		black.scrollFactor.set();
		black.camera = cameraUI;
		add(black);

		new FlxTimer().start(0.2, (t) ->
		{
			FlxG.sound.music.play();
			blackT = FlxTween.tween(black, {alpha: 0}, 2.5);
		});
	}
	else
	{
		blur = 0;
	}

	actived = loaded;

	setupOptionsStuff();
}

function beatHit()
{
	if (counter >= await)
		logo.animation.play('loop');
}

var opHeader:FlxText;
var opGameTxt:FlxText;
var opGraphTxt:FlxText;

function setupOptionsStuff()
{
	// options stuff
	opHeader = new FlxText(FlxG.width + 70, 100);
	opHeader.setFormat(Paths.font("undertale-hud.ttf"), 42, 0xFFFFFFFF);
	opHeader.cameras = [cameraUI];
	add(opHeader);

	opGameTxt = new FlxText(FlxG.width + 90, opHeader.y + opHeader.height + 25);
	opGameTxt.setFormat(Paths.font("pixelmax.ttf"), 42, 0xFFFFFFFF);
	opGameTxt.cameras = [cameraUI];
	opGameTxt.text = "Disable Modcharts......\n. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .\nDownscroll.......";
	add(opGameTxt);
	opHeader.text = "Gameplay....\n\n\n\n\n\n\n\nGraphics....";

	opGraphTxt = new FlxText(FlxG.width + 90, opGameTxt.y + 405);
	opGraphTxt.setFormat(Paths.font("pixelmax.ttf"), 42, 0xFFFFFFFF);
	opGraphTxt.cameras = [cameraUI];
	opGraphTxt.text = "Disable Modchart......\nKill myself...";
	add(opGraphTxt);
}

// scene shit
var SCENE_MENU = 0x00;
var SCENE_OPTIONS = 0x01;
var scenePositions = [SCENE_MENU => 0, SCENE_OPTIONS => FlxG.width];
var currentScene = SCENE_MENU;

function update(elapsed)
{
	heatShader.iTime = tmr;
	heatShader2.iTime = tmr;
	sparkles.iTime = tmr;

	tmr += elapsed * 1.5 * (actived ? 1 : 0.25);

	final scenePos = scenePositions.get(currentScene);

	// lerp is underrated
	camera.scroll.x = CoolUtil.fpsLerp(camera.scroll.x, camX, 0.08);
	camera.scroll.y = CoolUtil.fpsLerp(camera.scroll.y, camY, 0.08);

	cameraUI.scroll.x = CoolUtil.fpsLerp(cameraUI.scroll.x, scenePos + camX, 0.08);
	cameraUI.scroll.y = CoolUtil.fpsLerp(cameraUI.scroll.y, camY, 0.08);

	cameraUI.zoom = camera.zoom;

	updateMenu(elapsed);
	updateOptions(elapsed);
}

function updateOptions(elapsed)
{
	final isHere = currentScene == SCENE_OPTIONS;
	if (isHere && controls.BACK)
	{
		currentScene = SCENE_MENU;
		return;
	}
}

function updateMenu(elapsed)
{
	final isHere = currentScene == SCENE_MENU;

	if (!actived)
	{
		counter = 0;
		transP = 1;

		if (FlxG.mouse.justPressed || controls.ACCEPT)
		{
			if (blackT != null)
			{
				// hscript is sometimes weird
				blackT?._object?.alpha = 0;
				blackT?.cancel();
			}

			CoolUtil.playMenuSFX(1);
			actived = true;
			bloomIntensity = 3;
			camera.zoom = 1.125;
		}

		return;
	}
	else
	{
		counter += elapsed;
		lensBlur.iAmount = blur = CoolUtil.fpsLerp(blur, 0, 0.125);
	}

	bloomIntensity = CoolUtil.fpsLerp(bloomIntensity, 0, 0.05);
	bloomShader.iTime = bloomIntensity;
	camera.zoom = CoolUtil.fpsLerp(camera.zoom, 1, 0.05);

	if (!loaded)
	{
		transP = CoolUtil.fpsLerp(transP, 0, 0.05);
	}
	else
	{
		counter = await;
		transP = 0;
	}

	if (1 == 0)
	{
		gradient.scale.y = 2;
		// gradient.scale.y = (2.5 - Math.abs(FlxMath.fastSin(Conductor.curBeatFloat * Math.PI)) * 1.5) * (1 - transP);
		gradient.updateHitbox();
		gradient.y = FlxG.height - gradient.height;
		gradient.screenCenter(FlxAxes.X);
		gradient.alpha = 0.8;
	}

	if (isHere)
		updateSelection();

	sans.x = logo.x + (logo.width - sans.width) * .5;
	sans.y = logo.y + logo.height * .85 - sans.height;
	logo.x = FlxMath.lerp(FlxG.width / 2 - logo.width / 2, LOGO_BASE_X, 1 - transP);
	optionsB.y = -optionsB.height * transP + 30 * (1 - transP);

	// bro im a genius
	logo.y = LOGO_BASE_Y;
	logo.scale.x = logo.scale.y = LOGO_SCALE;

	if (transP <= 0.1)
	{
		camX = FlxG.mouse.screenX * -0.01;
		camY = FlxG.mouse.screenY * -0.01;
		// updateParticles(elapsed);
	}

	final seven = FlxG.keys.justPressed.SEVEN;
	final modSwitch = controls.SWITCHMOD;

	if (FlxG.keys.justPressed.T)
	{
		// FlxG.switchState(new ModState('ut/UndertaleTest'));

		var s = new UIState();
		s.scriptName = "ut/AttackEditor";
		FlxG.switchState(s);
	}
	if (seven)
		openSubState(new EditorPicker());
	if (modSwitch)
		openSubState(new ModSwitchMenu());
	if (seven || modSwitch)
		persistentUpdate = false;
}

var mouse = true;

function updateSelection()
{
	var optionsHovered = FlxG.mouse.overlaps(optionsB);
	optionsB.alpha = CoolUtil.fpsLerp(optionsB.alpha, optionsHovered ? 1 : ALPHA_SELECTED_MULT, LSPEED);
	optionsB.color = FlxColor.interpolate(optionsB.color, optionsHovered ? 0xFFFFFFFF : 0xFFCECECE, 60 * FlxG.elapsed * LSPEED * 3);

	if (optionsHovered)
	{
		if (curSelect != 3)
			CoolUtil.playMenuSFX(0, 0.7);
		curSelect = 3;
		if (FlxG.mouse.justReleased)
			confirmItem(3);
	}

	itemsGrp.forEach(item ->
	{
		final ovrlp = FlxG.mouse.overlaps(item) && !choised;
		final selected = (ovrlp && mouse) || (curSelect == item.ID);
		final canPress = curSelect == lastSelected && !choised;

		if (selected && curSelect != item.ID)
		{
			CoolUtil.playMenuSFX(0, 0.7);
			curSelect = item.ID;
		}

		if (canPress && ((ovrlp && FlxG.mouse.justReleased && mouse) || (curSelect == item.ID && !mouse && controls.ACCEPT)))
			confirmItem(curSelect);

		item.x = (BASE_X - item.width / 2) + (FlxG.width * (1.5 * transP * (item.ID + 1)));
		item.offset.y = selected ? sFOff : 0;

		item.scale.x = item.scale.y = CoolUtil.fpsLerp(item.scale.x, 1.3 * ITEM_SCALE * (selected ? 1 : SCALE_SELECTED_MULT), LSPEED);
		item.alpha = CoolUtil.fpsLerp(item.alpha, selected ? 1 : ALPHA_SELECTED_MULT, LSPEED);
		item.color = FlxColor.interpolate(item.color, selected ? COLOR_SELECTED : 0xFFFFFFFF, 60 * FlxG.elapsed * LSPEED * 3);

		if (ovrlp)
			ov = ovrlp;
	});

	if (FlxG.mouse.justMoved && !mouse)
		mouse = true;

	if (controls.DOWN_P || controls.UP_P)
	{
		curSelect += controls.UP_P ? -1 : 1;
		mouse = false;
	}

	if (!mouse)
	{
		curSelect = FlxMath.wrap(curSelect, 0, itemsGrp.length - 1);
	}

	lastSelected = curSelect;
}

function confirmItem(id)
{
	choised = true;

	loaded = true;

	switch (id)
	{
		case 0:
			bloomIntensity = 2;
			camera.zoom = 1.05;

			CoolUtil.playMenuSFX(1);

			new FlxTimer().start(Conductor.crochet / 1000, (t) ->
			{
				FlxG.switchState(new ModState('ut/Play'));
			});
		case 1:
			FlxG.switchState(new CreditsMain());
		case 2:
			// gallery
			trace('AUN NO HAY GALERIAAA');
		case 3:
			currentScene = SCENE_OPTIONS;
		default:
			trace('da fuck');
	}
}

var BASE_X = FlxG.width * 0.72;
var BASE_Y = FlxG.height * 0.525;
var SPACING_X = 0;
var SPACING_Y = 32;
var LSPEED = 0.105;
var ITEM_SCALE = 1;
var SCALE_SELECTED_MULT = 0.98;
var ALPHA_SELECTED_MULT = 0.55;
var COLOR_SELECTED = 0xFFFFEE00;
var LOGO_BASE_X = FlxG.width * 0.075;
var LOGO_BASE_Y = FlxG.height * .555;
var LOGO_SCALE = 0.425;
var sTwnAmp = 3;
var sTwnDiv = 2;
var sFOff = 0;
