var head:FlxSprite;
var torso:FlxSprite;
var legs:FlxSprite;

function postCreate() {
	head = new FlxSprite().loadGraphic(Paths.image('characters/pixel1/head'));
	addHere(head);

	torso = new FlxSprite().loadGraphic(Paths.image('characters/pixel1/torso'));
	addHere(torso);

	legs = new FlxSprite().loadGraphic(Paths.image('characters/pixel1/legs'));
	addHere(legs);

	this.pixelPerfectRender = true;
}

function positionSprites() {
	for (shit in [head, torso, legs]) {
		shit.scale.set(this.scale.x, this.scale.y);
		shit.updateHitbox();
		shit.setPosition(this.x, this.y);
		shit.offset.set(this.globalOffset.x * (this.isPlayer != this.playerOffsets ? 1 : -1), -this.globalOffset.y);
		shit.frameOffset.set(this.getAnimOffset("idle").x, this.getAnimOffset("idle").y);
		shit.antialiasing = false;

		shit.pixelPerfectRender = true;
	}

	updateHead();
	updateTorso();
	updateLegs();
}

function updateHead() {
	final curBeatFloat = (Conductor.curBeatFloat + (Conductor.crochet * 0.001 * .5)) * Math.PI;
	// torso offset
	final scale = 2 / (3 - FlxMath.fastCos(2 * curBeatFloat));
	final infX = scale * FlxMath.fastCos(curBeatFloat);
	final infY = scale * FlxMath.fastSin(curBeatFloat * 2) / 2;

	head.x += 5 + pixelize(infX) * 5;
	head.y += pixelize(infY) * 5;
	head.angle = pixelize(FlxMath.fastSin(curBeatFloat)) * 2;
}

function updateTorso() {
	final curBeatFloat = Conductor.curBeatFloat * Math.PI;
	// torso offset
	final scale = 2 / (3 - FlxMath.fastCos(2 * curBeatFloat));
	final infX = scale * FlxMath.fastCos(curBeatFloat);
	final infY = scale * FlxMath.fastSin(curBeatFloat * 2) / 2;

	torso.x += pixelize(infX) * 5;
	torso.y += pixelize(infY) * 5;
}

function updateLegs() {
	final shit = FlxEase.cubeOut(Conductor.curBeatFloat - Conductor.curBeat);
	legs.scale.x *= 1 + pixelize(1 - shit, 4) * 0.075;
	legs.scale.y *= 1 - pixelize(1 - shit, 4) * 0.025;
	legs.y += .5 * legs.height * (pixelize(1 - shit, 4) * 0.025);
}

var defSteps = 2;

function pixelize(t, ?steps) {
	if (steps == null)
		steps = defSteps;
	return Math.floor(t * steps) / steps;
}

function update(elapsed) {
	final condition = getAnimName() == "idle";
	if (condition) {
		head.camera = torso.camera = legs.camera = this.camera;
		positionSprites();
	}

	this.visible = !condition;
	head.visible = torso.visible = legs.visible = condition;
}

var lastAdded = null;

function addHere(obj) {
	PlayState.instance.add(obj);
}
