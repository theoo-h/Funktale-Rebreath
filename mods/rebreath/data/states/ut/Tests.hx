import flixel.FlxSprite;
import flixel.group.FlxTypedSpriteGroup;
import funkin.backend.MusicBeatGroup;
import ut.Blaster;
import ut.Bone;
import ut.Soul;
import ut.core.util.OBBCollision;

var blaster:Blaster;
var bone:Bone;
var soul:Soul;
var point;

function create() {
	trace('hello world');

	soul = new Soul();
	soul.screenCenter();
	soul.mode = 'normal';
	soul.size = 1.5;
	add(soul);

	bone = new Bone(50, 50, 400, 20);
	bone.angularVelocity = 100;
	bone.center = true;
	add(bone);

	bone.type = 'orange';
}

var time = 0;

function postUpdate(e) {
	bone.x = FlxG.width * .5;
	bone.y = FlxG.height * .5;

	soul.updateMovement(e);

	trace(bone.resolveCollision(soul));
}
