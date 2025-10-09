//
import flixel.math.FlxAngle;
import flixel.tweens.FlxTween;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxSort;
import funkin.backend.assets.Paths;
import funkin.backend.utils.CoolUtil;
import openfl.Assets;
import sys.FileSystem;
import ut.Blaster;
import ut.Bone;
import ut.Platform;
import ut.core.util.ControllerUtil;

final EVENT_BLASTER = 0x01;
final EVENT_BONE = 0x02;
final EVENT_EDIT_BONE = 0x03;
final EVENT_EDIT_BOX = 0x04;
final EVENT_EDIT_SOUL = 0x05;
final EVENT_PLATFORM = 0x06;
final EVENT_EDIT_PLATFORM = 0x07;
var events = [];
var blasterEvents = [];
var boneEvents = [];
var editBoneEvents = [];
var editBoxEvents = [];
var editSoulEvents = [];
var platformEvents = [];
var editPlatformEvents = [];
var platformsItems = [];

function minusShit(val, rep)
{
	return val == -1 ? rep : val;
}

public function loadAttacks()
{
	var file = fromEditor ? Paths.json("___tmpAttacks") : Paths.json('attacks/' + curSongID);

	if (!fromEditor && !Assets.exists(file))
		trace('[Attack Loader] Attack File wasn\'t found !');
	else
		trace('[Attack Loader] Attack File was found ! Loading...');

	var content = Assets.getText(file);

	final fileEvents = Json.parse(content);

	if (fileEvents != null)
	{
		for (ev in fileEvents.events)
			addEvent(ev);
		fileEvents = null;
	}
}

// handlers
function isMovingAway(obj)
{
	final cam = obj.camera;
	var cx = cam.scroll.x;
	var cy = cam.scroll.y;
	var cw = cam.width;
	var ch = cam.height;

	return ((obj.x < cx && obj.velocity.x <= 0)
		|| (obj.x > cx + cw && obj.velocity.x >= 0)
		|| (obj.y < cy && obj.velocity.y <= 0)
		|| (obj.y > cy + ch && obj.velocity.y >= 0));
}

function isMovingTowardScreen(obj)
{
	final cam = obj.camera;
	var cx = cam.scroll.x;
	var cy = cam.scroll.y;
	var cw = cam.width;
	var ch = cam.height;

	return ((obj.x < cx && obj.velocity.x > 0)
		|| (obj.x > cx + cw && obj.velocity.x < 0)
		|| (obj.y < cy && obj.velocity.y > 0)
		|| (obj.y > cy + ch && obj.velocity.y < 0));
}

// TODO: preload/cache all the bone mods on a map, and use fixed array + index counter (no shifting)
// TODO: pooling ??
var boneBuffer = [];

function updateBoneEvents(curTime, elapsed)
{
	// push bone events to bone's buffer
	while (boneEvents.length > 0 && boneEvents[0].time <= curTime)
	{
		final currentEvent = boneEvents.shift();
		final mods = [];
		for (mod in editBoneEvents)
		{
			if (mod.params[0].id == currentEvent.params[0].id)
				mods.push(mod);
		}
		boneBuffer.push({
			{
				obj: null,
				ev: currentEvent,
				mods: mods,
				_modTween: null
			}
		});

		for (mod in mods)
			editBoneEvents.remove(mod);

		trace('Pushed bone to buffer, mods: ' + mods.length);
	}

	// process the entire bone timeline
	for (item in boneBuffer)
	{
		// rare case
		if (item == null)
			continue;
		var bone = item.obj;
		var data = item.ev.params[0];
		var mods = item.mods;

		var delay = curTime - item.ev.time - elapsed;

		if (bone == null)
		{
			bone = new Bone(data.positionX, data.positionY, data.width, data.height);
			bone.center = true;
			bone.camera = (data?.out ?? false) ? camUndertale : camClipped;
			bones.add(bone);

			// add data
			bone.indentifier = data.id;
			bone.type = data?.mode ?? "normal";

			bone.angle = data.angle;

			bone.velocity.x = data.vX;
			bone.velocity.y = data.vY;
			bone.angularVelocity = data.vA;

			// fix random gaps
			bone.updateMotion(delay * 0.001);
			bone.updateBone();
			trace(delay * 0.001);
		}
		else
		{
			if (mods.length == 0 && item._modTweens == null)
			{
				final isOnScreen = bone.isOnScreen(bone.camera);
				var kill = false;
				if (bone.hasSeen && !isOnScreen && isMovingAway(bone))
					kill = true;

				if (!bone.hasSeen && !isOnScreen && !isMovingTowardScreen(bone))
					kill = true;

				if (isOnScreen)
					bone.hasSeen = true;

				if (kill)
				{
					_queueArray.push(item);
					continue;
				}
			}
		}

		// find mods and execute them
		while (mods.length > 0 && mods[0].time <= curTime)
		{
			final mod = mods.shift();
			final dataMod = mod.params[0];

			if (dataMod.mode != null && dataMod.mode != "*last*" || dataMod.mode != "")
				bone.type = dataMod.mode;

			if (item._modTween != null)
				item._modTween.cancel();

			var baseX = bone.x;
			var baseY = bone.y;
			var baseA = bone.angle;

			item._modTweens = FlxTween.num(0, 1, dataMod.tweenDur, {
				ease: CoolUtil.flxeaseFromString(dataMod.tweenName, '') ?? FlxEase.linear
			}, (v) ->
				{
					if (dataMod.positionX != -1)
						bone.x = FlxMath.lerp(baseX, dataMod.positionX, v);
					if (dataMod.positionY != -1)
						bone.y = FlxMath.lerp(baseY, dataMod.positionY, v);
					if (dataMod.angle != -1)
						bone.angle = FlxMath.lerp(baseA, dataMod.angle, v);

					if (dataMod.width != -1)
						bone.boneWidth = FlxMath.lerp(data.width, dataMod.width, v);
					if (dataMod.height != -1)
						bone.boneHeight = FlxMath.lerp(data.height, dataMod.height, v);

					if (dataMod.vX != -1)
						bone.velocity.x = FlxMath.lerp(data.vX, dataMod.vX, v);
					if (dataMod.vY != -1)
						bone.velocity.y = FlxMath.lerp(data.vY, dataMod.vY, v);
					if (dataMod.vA != -1)
						bone.angularVelocity = FlxMath.lerp(data.vA, dataMod.vA, v);
				});

			// only run 1 mod at same frame
			break;
		}
		item.obj = bone;
	}
	bones.update(elapsed);

	// delete bones
	for (item in _queueArray)
	{
		boneBuffer.remove(item);

		item.obj.kill();
		item.obj.destroy();
	}

	if (_queueArray.length > 0)
	{
		trace('Trashed ' + _queueArray.length + ' bones');
		_queueArray = FlxArrayUtil.clearArray(_queueArray);
	}
}

var boxTween:FlxTween;

function defaultVal(val, rep)
{
	return val == -1 ? rep : val;
}

function updateBoxEvents(curTime, elapsed)
{
	// run da events
	while (editBoxEvents.length > 0 && editBoxEvents[0].time <= curTime)
	{
		final currentEvent = editBoxEvents.shift();
		final data = currentEvent.params[0];

		if (boxTween != null)
			boxTween.cancel();

		var lastX = box.x;
		var lastY = box.y;
		var lastA = box.angle;
		var lastWidth = box.boxWidth;
		var lastHeight = box.boxHeight;

		boxTween = FlxTween.num(0, 1, data.tweenDur, {
			ease: CoolUtil.flxeaseFromString(data.tweenName, '') ?? FlxEase.linear
		}, (v) ->
			{
				if (data.width != -1)
					box.boxWidth = FlxMath.lerp(lastWidth, data.width, v);
				if (data.height != -1)
					box.boxHeight = FlxMath.lerp(lastHeight, data.height, v);

				box.x = FlxMath.lerp(lastX, defaultVal(data.positionX, lastX) + (lastWidth - defaultVal(data.width, lastWidth)) * .5, v);
				box.y = FlxMath.lerp(lastY, defaultVal(data.positionY, lastY) + (lastHeight - defaultVal(data.height, lastHeight)) * .5, v);
				if (data.angle != -1)
					box.angle = FlxMath.lerp(lastA, dataEdit.angle, v);
			});

		trace('Running box event');
	}
}

var lastSoulGrav = 1;
var lastSoulSpeed = 1;
var lastSoulAngle = 1;

function updateSoulEvents(curTime, elapsed)
{
	while (editSoulEvents.length > 0 && editSoulEvents[0].time <= curTime)
	{
		final currentEvent = editSoulEvents.shift();
		final data = currentEvent.params[0];

		soul.angle = defaultVal(lastSoulAngle = data.groundAngle, lastSoulAngle);

		if (soul.mode != data.mode)
			soul.mode = data.mode;

		if (soul.mode == 'blue')
			soul.behavior.gravityMult = defaultVal(lastSoulGrav = data.gravityMult, lastSoulGrav);
		soul.behavior.speed = defaultVal(lastSoulSpeed = data.speedMult, lastSoulSpeed);

		trace('Running soul event');
	}
}

// TODO: pooling?, batching? IDK
var blasterBuffer = [];

function updateBlasterEvents(curTime, elapsed)
{
	while (blasterEvents.length > 0 && blasterEvents[0].time <= curTime)
	{
		final currentEvent = blasterEvents.shift();
		final data = currentEvent.params[0];

		blasterBuffer.push({
			obj: null,
			ev: data
		});
		trace('Pushed blaster to list');
	}

	for (item in blasterBuffer)
	{
		final blaster = item.obj;
		final data = item.ev;

		if (blaster == null)
		{
			blaster = new Blaster();
			blaster.quiet = data.quiet;
			blaster.camera = camUndertale;
			blasters.add(blaster);

			if (data.pointTo)
			{
				var originX = (soul.x + soul.width * .5) - data.attackPosition.x;
				var originY = (soul.y + soul.height * .5) - data.attackPosition.y;
				data.attackAngle = FlxAngle.degreesFromOrigin(originX, originY);
			}

			blaster.setup(data);
			blaster.start();
		}
		else
		{
			if (blaster.useless && !blaster.head.isOnScreen(camUndertale))
			{
				_queueArray.push(item);
				continue;
			}
		}

		item.obj = blaster;
	}

	// delete bones
	for (item in _queueArray)
	{
		blasterBuffer.remove(item);

		item.obj.kill();
		item.obj.destroy();
	}

	if (_queueArray.length > 0)
	{
		trace('Trashed ' + _queueArray.length + ' blasters');
		_queueArray = FlxArrayUtil.clearArray(_queueArray);
	}

	blasters.update(elapsed);
}

// platform's buffer
var platformBuffer = [];

function updatePlatformEvents(curTime, elapsed)
{
	// push bone events to platform's buffer
	while (platformEvents.length > 0 && platformEvents[0].time <= curTime)
	{
		final currentEvent = platformEvents.shift();
		final mods = [];
		for (mod in editPlatformEvents)
		{
			if (mod.params[0].id == currentEvent.params[0].id)
				mods.push(mod);
		}
		platformBuffer.push({
			{
				obj: null,
				ev: currentEvent,
				mods: mods,
				_modTween: null
			}
		});

		for (mod in mods)
			editPlatformEvents.remove(mod);

		trace('Pushed platform to buffer, mods: ' + mods.length);
	}

	// process the entire platform timeline
	for (item in platformBuffer)
	{
		// rare case
		if (item == null)
			continue;
		var platform = item.obj;
		var data = item.ev.params[0];
		var mods = item.mods;

		if (platform == null)
		{
			platform = new Platform(0, 0, 1, 1);
			platform.thickness = 6;
			platform.solid = true;
			platform.immovable = true;
			platform.moves = false;
			platforms.add(platform);

			platform.setPosition(data.positionX, data.positionY);
			platform.velocity.x = data.vX;
			platform.velocity.y = data.vY;
			platform.boxWidth = data.width;
			platform.boxHeight = data.height;
		}
		else
		{
			if (mods.length == 0 && item._modTweens == null)
			{
				final isOnScreen = platform.isOnScreen(platform.camera);
				var kill = false;
				if (platform.hasSeen && !isOnScreen && isMovingAway(platform))
					kill = true;

				if (!platform.hasSeen && !isOnScreen && !isMovingTowardScreen(platform))
					kill = true;

				if (isOnScreen)
					platform.hasSeen = true;

				if (kill)
				{
					_queueArray.push(item);
					continue;
				}
			}
		}
		platform.allowCollisions = getGrounds(soul.angle);

		// find mods and execute them
		while (mods.length > 0 && mods[0].time <= curTime)
		{
			final mod = mods.shift();
			final dataMod = mod.params[0];

			if (item._modTween != null)
				item._modTween.cancel();

			item._modTweens = FlxTween.num(0, 1, dataMod.tweenDur, {
				ease: CoolUtil.flxeaseFromString(dataMod.tweenName, '') ?? FlxEase.linear,
				onComplete: (t) ->
				{
					item._modTweens.remove(t);
				}
			}, (v) ->
				{
					if (dataMod.positionX != -1)
						platform.x = FlxMath.lerp(platform.x, dataMod.positionX, v);
					if (dataMod.positionY != -1)
						platform.y = FlxMath.lerp(platform.y, dataMod.positionY, v);

					if (dataMod.width != -1)
						platform.boxWidth = FlxMath.lerp(data.width, dataMod.width, v);
					if (dataMod.height != -1)
						platform.boxHeight = FlxMath.lerp(data.height, dataMod.height, v);

					if (dataMod.vX != -1)
						platform.velocity.x = FlxMath.lerp(data.vX, dataMod.vX, v);
					if (dataMod.vY != -1)
						platform.velocity.y = FlxMath.lerp(data.vY, dataMod.vY, v);
				});
		}

		platform.updateMotion(elapsed);
		item.obj = platform;
	}

	// delete platforms
	for (item in _queueArray)
	{
		platformBuffer.remove(item);

		item.obj.kill();
		item.obj.destroy();
	}

	if (_queueArray.length > 0)
	{
		trace('Trashed ' + _queueArray.length + ' platform');
		_queueArray = FlxArrayUtil.clearArray(_queueArray);
	}
}

public function updateAttacksEvents(elapsed:Float)
{
	var curTime = Conductor.songPosition;

	updateBoneEvents(curTime, elapsed);
	updateBoxEvents(curTime, elapsed);
	updateSoulEvents(curTime, elapsed);
	updateBlasterEvents(curTime, elapsed);
	updatePlatformEvents(curTime, elapsed);
}

var _queueArray = [];

function getGrounds(angle:Float):Int
{
	var LEFT = 0x0001;
	var RIGHT = 0x0010;
	var UP = 0x0100;
	var DOWN = 0x1000;

	angle = (angle) % 360;
	if (angle < 0)
		angle += 360;

	if (angle >= 315 || angle < 45)
		return UP;
	if (angle >= 45 && angle < 135)
		return LEFT;
	if (angle >= 135 && angle < 225)
		return DOWN;
	if (angle >= 225 && angle < 315)
		return RIGHT;

	return UP;
}

function addEvent(event)
{
	events.push(event);
	switch (event.type)
	{
		case EVENT_BONE:
			boneEvents.push(event);
		case EVENT_BLASTER:
			final params = event.params[0];
			params.initialPosition = FlxPoint.get(params.initialPositionX, params.initialPositionY);
			params.attackPosition = FlxPoint.get(params.attackPositionX, params.attackPositionY);
			blasterEvents.push(event);
		case EVENT_EDIT_BONE:
			editBoneEvents.push(event);
		case EVENT_EDIT_BOX:
			editBoxEvents.push(event);
		case EVENT_EDIT_SOUL:
			editSoulEvents.push(event);
		case EVENT_PLATFORM:
			platformEvents.push(event);
		case EVENT_EDIT_PLATFORM:
			editPlatformEvents.push(event);
	}

	sortEvents();
}

function sortEvents()
{
	events.sort(function(a, b) return Reflect.compare(a.time, b.time));
	boneEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	blasterEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editBoneEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editBoxEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editSoulEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	platformEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editPlatformEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
}
