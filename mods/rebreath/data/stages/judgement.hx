importScript('data/core/CameraMovement');
import flixel.FlxSprite;
import openfl.display.BlendMode;

var perspective = new CustomShader('floor');
var depth = 0.45;

var floorData = {
	x: 0,
	y: -40,
	scale: {x: 4, y: 4},
	width: FlxG.width,
	height: FlxG.height,
	depth: depth
};

// BG ELEMENTS
var background:FlxSprite;
var floor:FlxSprite;
var shading:FlxSprite;
var decoration:FlxSprite;
public var JUDGEMENT_LIGHTNING:FlxSprite;
public var JUDGEMENT_FRONT_PILLARS:FlxSprite;
var zoom = 0.15;

var addBG = (obj) -> {
	obj.scale.set(obj.scale.x - zoom, obj.scale.y - zoom);
	insert(members.indexOf(dad), obj);
}

function postCreate() {
	floor = new FlxSprite(-150, floorData.y);
	floor.setPosition(0, 685);
	floor.loadGraphic(Paths.image('judgement/floor_grid'));
	floor.shader = perspective;
	floor.setGraphicSize(floorData.width, floorData.height);
	floor.offset.x -= 15;

	shading = new FlxSprite();
	shading.loadGraphic(Paths.image('judgement/floor_shading'));
	shading.screenCenter();
	shading.y += 72;
	shading.blend = BlendMode.MULTIPLY;

	windows = new FlxSprite();
	windows.loadGraphic(Paths.image('judgement/windows'));
	windows.screenCenter();

	background = new FlxSprite();
	background.loadGraphic(Paths.image('judgement/background'));
	background.screenCenter();

	decoration = new FlxSprite(0, -465);
	decoration.loadGraphic(Paths.image('judgement/decoration'));
	decoration.screenCenter(FlxAxes.X);

	JUDGEMENT_LIGHTNING = new FlxSprite();
	JUDGEMENT_LIGHTNING.loadGraphic(Paths.image('judgement/lightning'));
	JUDGEMENT_LIGHTNING.screenCenter();
	JUDGEMENT_LIGHTNING.alpha = 0.3;
	JUDGEMENT_LIGHTNING.blend = BlendMode.LIGHTEN;

	JUDGEMENT_FRONT_PILLARS = new FlxSprite();
	JUDGEMENT_FRONT_PILLARS.loadGraphic(Paths.image('judgement/front_pillars'));
	JUDGEMENT_FRONT_PILLARS.scale.set(2.15, 2.15);
	JUDGEMENT_FRONT_PILLARS.updateHitbox();
	JUDGEMENT_FRONT_PILLARS.screenCenter();
	JUDGEMENT_FRONT_PILLARS.y += 100;

	floor.scrollFactor.set(0.6, 0.6);
	shading.scrollFactor.set(0.6, 0.6);
	background.scrollFactor.set(0.6, 0.6);
	decoration.scrollFactor.set(0.6, 0.6);
	JUDGEMENT_LIGHTNING.scrollFactor.set(0.6, 0.6);
	JUDGEMENT_FRONT_PILLARS.scrollFactor.set(1, 1);

	boyfriend.scrollFactor.set(0.6, 0.6);
	dad.scrollFactor.set(0.6, 0.6);

	addBG(background);
	addBG(floor);
	addBG(shading);
	addBG(decoration);

	add(JUDGEMENT_LIGHTNING);
	add(JUDGEMENT_FRONT_PILLARS);

	perspective.u_top = [0, 1];
	perspective.u_depth = depth;

	camera.addShader(new CustomShader('effects/judgement'));
}

function onCameraMove(ev) {
	ev.position = ev.strumLine.characters[0].getCameraPosition();
}

function update(elapsed) {
	// 3D Floor Arrangements
	var cam = {
		x: (camera.scroll.x * scrollFactor.x) + FlxG.width / 2 + vanishOff.x,
		y: (camera.scroll.y * scrollFactor.y) + FlxG.height / 2 + vanishOff.y
	};
	var vanish = {
		x: (cam.x - floorData.x) / floorData.width,
		y: 1 - (cam.y - floorData.y) / floorData.height
	};

	var depthVanishX = floorData.depth * vanish.x;
	var depthVanishY = floorData.depth * vanish.y;
	var topX = depthVanishX;
	var topY = depthVanishX - floorData.depth + 1;

	if (topY > 1 || topX < 0) {
		floor.scale.set(floorData.scale.x * (1 + floorData.depth * (vanish.x - ((topY > 1) ? 1 : 0))), floorData.scale.y * depthVanishY);
	} else {
		floor.scale.set(floorData.scale.x, floorData.scale.y * depthVanishY);
	}
	perspective.u_top = [topX, topY];
}

var vanishOff = {
	x: -2.5,
	y: -10
};

var scrollFactor = {
	x: -0.01,
	y: 0
}
