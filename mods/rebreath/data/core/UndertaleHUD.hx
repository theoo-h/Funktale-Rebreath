//
import Sys;
import flixel.math.FlxMath;
import funkin.game.GameOverSubstate;

var barBG:FlxSprite;
var barKR:FlxSprite;
var bar:FlxSprite;
var barW = 275;
var barH = 40;

// KR DRAIN SPEED
var krDS:Float = 0.0009;
var hpT:FlxText;
var krT:FlxText;
var nameT:FlxText;
var levelT:FlxText;

function postCreate()
{
	trace("[ ADDED UT HUD ]");

	healthBarBG.visible = healthBar.visible = iconP1.visible = iconP2.visible = false;

	barBG = new FlxSprite();
	barBG.makeGraphic(barW, barH, 0xFFFF0000);
	barBG.screenCenter(FlxAxes.X);
	barBG.cameras = [camHUD];
	barBG.y = FlxG.height * 0.885;
	barBG.centerOrigin();
	add(barBG);

	barKR = new FlxSprite();
	barKR.makeGraphic(barW, barH, 0xFFFF00DD);
	barKR.screenCenter(FlxAxes.X);
	barKR.cameras = [camHUD];
	barKR.y = FlxG.height * 0.885;
	add(barKR);

	bar = new FlxSprite();
	bar.makeGraphic(barW, barH, 0xFFFFFF00);
	bar.screenCenter(FlxAxes.X);
	bar.cameras = [camHUD];
	bar.y = FlxG.height * 0.885;
	add(bar);

	hpT = new FlxText();
	hpT.setFormat(Paths.font("undertale-hud.ttf"), 22, 0xFFFFFFFF);
	hpT.text = "hp";
	hpT.cameras = [camHUD];
	add(hpT);

	krT = new FlxText();
	krT.setFormat(Paths.font("undertale-hud.ttf"), 22, 0xFFFFFFFF);
	krT.text = "kr";
	krT.cameras = [camHUD];
	add(krT);
	hpT.scale.set(1, 0.8);
	krT.scale.set(1, 0.8);

	nameT = new FlxText();
	nameT.setFormat(Paths.font("undertale-hud.ttf"), 24, 0xFFFFFFFF);
	nameT.text = Sys.environment().get("USERNAME");
	nameT.cameras = [camHUD];
	add(nameT);

	levelT = new FlxText();
	levelT.setFormat(Paths.font("undertale-hud.ttf"), 24, 0xFFFFFFFF);
	levelT.text = "lv 69";
	levelT.cameras = [camHUD];
	add(levelT);

	for (bar in [barKR, bar, barBG])
		bar.origin.set(0, bar.height / 2);

	missesTxt.visible = scoreTxt.visible = accuracyTxt.visible = false;

	health = 2;

	PauseSubState.script = 'data/core/PauseLB';
	GameOverSubstate.script = 'data/core/GameOverLB';
}

function postUpdate(elapsed:Float)
{
	var baseY = (isUndertale ? FlxG.height * 0.8229 : FlxG.height * 0.885);

	barBG.y = bar.y = barKR.y = baseY;

	bar.scale.x = FlxMath.bound(FlxMath.remapToRange(health, 0, 2, 0, 1), 0, 1) * barBG.scale.x;
	bar.scale.y = barBG.scale.y;

	barKR.scale.x = FlxMath.lerp(barKR.scale.x, bar.scale.x, krDS);
	barKR.scale.y = barBG.scale.y;

	if (barKR.scale.x < bar.scale.x)
		barKR.scale.x = bar.scale.x;

	hpT.x = barBG.x - hpT.width - 5;
	hpT.y = barBG.y + barBG.height * 0.5 - hpT.height * 0.5;

	krT.x = barBG.x + barBG.width + 8;
	krT.y = barBG.y + barBG.height * 0.5 - krT.height * 0.5;

	nameT.x = FlxG.width * 0.12;
	nameT.y = barBG.y + barBG.height * 0.5 - nameT.height * 0.5;

	levelT.x = nameT.x + nameT.width + FlxG.width * 0.03;
	levelT.y = barBG.y + barBG.height * 0.5 - levelT.height * 0.5;
}

var debug = false;

function onGameOver(e)
{
	// should i use 0 ?? works with lerp ??
	// nvm it dont work w/ lerp
	if (health <= 0 && barKR.scale.x > 0.002 && !debug)
		e.cancel();
}

// THOSE FUNCTIONS WILL ONLY WORK IF UNDERTALE MECHANICS ARE ENABLED (to enable they, import UndertaleMC script)
function onUndertaleSwitch(value)
{
	isUndertale = value;
	levelT.camera = nameT.camera = krT.camera = hpT.camera = bar.camera = barKR.camera = barBG.camera = isUndertale ? camUndertale : camHUD;
}

var undertaleShiw = false;
var isUndertale = false;
