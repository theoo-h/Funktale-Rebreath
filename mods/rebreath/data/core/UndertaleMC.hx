import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.text.FlxText.FlxTextBorderStyle;
import ut.Blaster;
import ut.Bone;
import ut.FightBox;
import ut.Platform;
import ut.Soul;
import ut.core.BoneGroup;

var debugger:FlxText;
public var soul:Soul;
public var box:FightBox;
public var bones:BoneGroup = new BoneGroup();
public var blasters:FlxTypedGroup<Blaster> = new FlxTypedGroup();
public var platforms:FlxTypedGroup<Platform> = new FlxTypedGroup();
var hud:FlxSprite;
public var healthDrain:Float = 0.0125;
public var canRegen:Bool = true;
public var blastersHurt:Bool = true;
public var bonesHurt:Bool = true;
public var camUndertale:FlxCamera;
public var camClipped:FlxCamera;
var clipShader = null;
public var generateGradient:Bool = false;
public var gradientColor:Int = 0xFFFFFFFF;
public var gradient:FlxSprite;
var prevUTVal:Bool = false;
public var undertale:Bool = false;
public var dialogBoxOpenSpeed:Float = 1;
public var dialogBox:Bool = false;
public var dialogText:FlxTypeText;
public var dialogSpeed:Float = 1;
public var dialogSounds:Array<String> = ['SND_TXT2'];
var prevDialogSounds:Array<String> = [];
public var dialogTextStr:String = '* Default text.';
public var startDialog:Bool = false;
public var boxWidth = 0;
public var boxHeight = 0;
public var soulScale = 1.7;
public var bw = constBoxWidth;
public var bh = constBoxHeight;
public var bx = constBoxX;
public var by = constBoxY;
public var bt = constBoxThickness;
var dialogBw = bw * 3.2;
var dialogBh = bh * 0.9;
var canAttack:Bool = true;
var attackPosition:FlxPoint = FlxPoint.get();
var attacking:Bool = false;
var attackLength = Conductor.crochet / 1000 * 2;
var attackTimer:Float = 0;

function postCreate()
{
	Blaster.DEFAULT_SFX_VOLUME = 0.25;
	importScript("data/core/AttackLoader.hx");

	scripts.call('onUndertaleSetup');

	camUndertale = new FlxCamera();
	camClipped = new FlxCamera();

	camUndertale.pixelPerfectRender = camClipped.pixelPerfectRender = true;
	camUndertale.antialiasing = camClipped.antialiasing = false;

	camUndertale.bgColor = 0xFF000000;
	camClipped.bgColor = 0x00000000;

	FlxG.cameras.remove(camHUD, false);
	FlxG.cameras.add(camUndertale, false);
	FlxG.cameras.add(camClipped, false);
	FlxG.cameras.add(camHUD, false);

	if (generateGradient)
	{
		gradient = new FlxSprite();
		gradient.loadGraphic(Paths.image('ut/ui/gradient'));
		gradient.scrollFactor.set(0.3, 0.3);
		gradient.color = gradientColor;
		gradient.width = FlxG.width * 5;
		gradient.cameras = [camUndertale];
		insert(0, gradient);
	}

	box = new FightBox();
	box.boxWidth = bw;
	box.boxHeight = bh;
	box.thickness = bt;
	box.setPosition(bx, by);
	box.update(0);
	box.cameras = [camUndertale];
	box._container.cameras = [camUndertale];
	add(box);

	soul = new Soul();
	soul.host = box;
	soul.size = 2.25;
	soul.antialiasing = false;
	soul.cameras = [camUndertale];
	soul.solid = true;
	soul.immovable = false;
	soul.pixelPerfectRender = soul.pixelPerfectPosition = true;
	add(soul);

	box.guest = soul;

	// Just in case
	soul.boxCenter(box);
	add(soul);

	platforms.camera = camUndertale;
	add(platforms);
	add(bones);
	add(blasters);

	blasters.active = bones.active = false;

	var hudScale = 1.2;

	hud = new FlxSprite();
	hud.loadGraphic(Paths.image('ut/hud'));
	hud.scale.set(hudScale, hudScale);
	hud.updateHitbox();
	hud.screenCenter(FlxAxes.X);
	hud.y = FlxG.height * 0.92 - hud.height / 2;
	hud.cameras = [camUndertale];
	add(hud);

	dialogText = new FlxTypeText(0, 0, '');
	dialogText.cameras = [camUndertale];
	dialogText.setFormat(Paths.font("determination-mono.ttf"), 48, 0xFFFFFF);
	add(dialogText);

	scripts.call('onUndertaleSetupPost');

	health = 2;

	camClipped.addShader(clipShader = new CustomShader('clipRect'));
	player.extra.set('soul', soul);
	player.extra.set('camUndertale', camUndertale);

	trace('[ ADDED UT MECHANICS ]');

	loadAttacks();
}

public var cBoxWidth = false;

function update(elapsed)
{
	updateAttacksEvents(elapsed);

	soul.updateMovement(elapsed);

	var grounded = false;
	FlxG.collide(soul, platforms, (soul, plat) ->
	{
		grounded = true;

		// fuck FlxObject.moves
		soul.x += plat.x - plat.last.x;
	});

	box.updateCollision();

	if (grounded)
		soul.grounded = true;

	if (onlyUndertale)
	{
		undertale = true;
	}

	if (undertaleQueue)
		undertale = curStep % 2 == 0;

	camUndertale.active = camClipped.active = camClipped.alive = camUndertale.alive = undertale;
	camGame.active = camGame.alive = !undertale;

	if (prevUTVal != undertale)
	{
		FlxG.sound.play(Paths.sound('ut/switch'), 0.2);
		scripts.call('onUndertaleSwitch', [undertale]);
	}
	if (prevDialogSounds != dialogSounds)
		dialogText.sounds = getDialogSounds();

	camUndertale.zoom = camHUD.zoom;
	camUndertale.angle = camHUD.angle;
	camUndertale.visible = undertale;

	camClipped.zoom = camHUD.zoom;
	camClipped.angle = camHUD.angle;
	camClipped.visible = undertale;

	final mp = box._container.getMidpoint();
	final midScreen = FlxPoint.get(FlxG.width / 2, FlxG.height / 2);

	// i hate hscript -theo
	mp.x -= midScreen.x;
	mp.y -= midScreen.y;
	mp.x *= camClipped.zoom;
	mp.y *= camClipped.zoom;
	mp.x += midScreen.x;
	mp.y += midScreen.y;

	final w = box.boxWidth * camClipped.zoom;
	final h = box.boxHeight * camClipped.zoom;
	clipShader.minX = FlxMath.remapToRange(mp.x - w / 2, 0, FlxG.width, 0, 1);
	clipShader.minY = FlxMath.remapToRange(mp.y - h / 2, 0, FlxG.height, 0, 1);
	clipShader.maxX = FlxMath.remapToRange(mp.x + w / 2, 0, FlxG.width, 0, 1);
	clipShader.maxY = FlxMath.remapToRange(mp.y + h / 2, 0, FlxG.height, 0, 1);
	mp.put();
	midScreen.put();

	if (blastersHurt)
	{
		blasters.forEach(blaster ->
		{
			if (blaster.resolveCollision(soul))
			{
				health -= healthDrain * 60 * FlxG.elapsed;
				blaster.hitsound();
			}
		});
	}
	if (bonesHurt)
	{
		bones.forEach(bone ->
		{
			if (bone.resolveCollision(soul))
			{
				health -= healthDrain * 60 * FlxG.elapsed;
				bone.hitsound();
			}
		});
	}
	if (gradient != null)
	{
		gradient.color = gradientColor;
		gradient.scale.y = 2.5 - Math.abs(FlxMath.fastSin(Conductor.curBeatFloat * Math.PI)) * 1.5;
		gradient.updateHitbox();
		gradient.y = FlxG.height - gradient.height;
		gradient.screenCenter(FlxAxes.X);
	}

	prevUTVal = undertale;
	prevDialogSounds = dialogSounds;

	if (cpuStrums.characters.length <= 1)
	{
		return;
	}
	var pixelOp = cpuStrums.characters[onlyUndertale ? 0 : 1];
	pixelOp.cameras = [camUndertale];

	if (FlxG.keys.justPressed.Z && !attacking && canAttack && undertale && dialogBox)
	{
		attacking = true;
		attackPosition.set(pixelOp.x, pixelOp.y);
		trace('atack');
	}
	if (attacking)
	{
		attackTimer += elapsed;

		pixelOp.x = attackPosition.x + FlxMath.fastSin(attackTimer / attackLength * Math.PI) * 100;

		if (attackTimer >= attackLength)
		{
			attackTimer = 0;
			attacking = false;
			pixelOp.x = attackPosition.x;
		}
	}
}

public var onlyUndertale:Bool = false;
public var undertaleQueue:Bool = false;

function updateBox()
{
	dialogText.x = (box.x + bw / 2) - box.width / 2 + 60;
	dialogText.y = box.y + 60;

	if (startDialog)
	{
		dialogText.resetText('');
		dialogText._finalText = dialogTextStr;
		dialogText.start(0.05 / dialogSpeed);
	}
	box.boxWidth = CoolUtil.fpsLerp(box.boxWidth, boxWidth, 0.125 * dialogBoxOpenSpeed);
	box.boxHeight = CoolUtil.fpsLerp(box.boxHeight, boxHeight, 0.125 * dialogBoxOpenSpeed);
	box.y = CoolUtil.fpsLerp(box.y, dialogBox ? (by + 30 - (bh - boxHeight) * 0.5) : by, 0.125 * dialogBoxOpenSpeed);
	soul.alpha = CoolUtil.fpsLerp(soul.alpha, dialogBox ? 0 : 1, 0.125 * dialogBoxOpenSpeed);
	dialogText.alpha = CoolUtil.fpsLerp(dialogText.alpha, dialogBox ? 1 : 0, 0.25 * dialogBoxOpenSpeed);

	soul.playable = soul.alpha >= 0.05 ? true : false;

	if (!dialogBox && dialogText._typing)
	{
		dialogBox.erase(0.12 / dialogSpeed);
	}

	startDialog = false;
}

function getDialogSounds()
{
	if (dialogSounds.length <= 0)
		return [];

	var flixelSounds = [];

	for (i in 0...dialogSounds.length)
	{
		final curSoundName = dialogSounds[i];
		flixelSounds.push(new FlxSound().loadEmbedded(Paths.sound('ut/dialog/' + curSoundName)));
	}

	return flixelSounds;
}

function onNoteHit(e)
{
	if (!canRegen)
		e.healthGain = 0;
}
