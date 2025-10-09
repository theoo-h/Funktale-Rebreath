import flixel.util.FlxSort;
import funkin.backend.assets.Paths;
import funkin.backend.utils.CoolUtil;
import openfl.Assets;
import ut.Blaster;
import ut.Bone;
import ut.Platform;

final EVENT_BLASTER = 0x01;
final EVENT_BONE = 0x02;
final EVENT_EDIT_BONE = 0x03;
final EVENT_EDIT_BOX = 0x04;
final EVENT_EDIT_SOUL = 0x05;
final EVENT_PLATFORM = 0x06;
final EVENT_EDIT_PLATFORM = 0x07;
var events = [];
var boneItems = [];
var blastersItems = [];
var blasterEvents = [];
var boneEvents = [];
var editBoneEvents = [];
var editBoxEvents = [];
var editSoulEvents = [];
var platformEvents = [];
var editPlatformEvents = [];
var platformsItems = [];

function minusShit(val, rep) {
	return val == -1 ? rep : val;
}

public function loadAttacks() {
	var file = Paths.json('battleSaving');
	var content = Assets.getText(file);

	final fileEvents = Json.parse(content);

	if (fileEvents != null) {
		for (ev in fileEvents.events) {
			addEvent(ev);
		}
		fileEvents = null;
	}
}

public function updateAttacksEvents(elapsed:Float) {
	var position = Conductor.songPosition;

	var blasterCount = 0;
	var boneCount = 0;
	var platformCount = 0;

	box.boxWidth = constBoxWidth;
	box.boxHeight = constBoxHeight;
	box.thickness = constBoxThickness;
	box.angle = 0;
	box.setPosition(constBoxX, constBoxY);

	var boxEdits = editBoxEvents.copy();
	boxEdits.sort(function(a, b) return Reflect.compare(a.time, b.time));

	for (i in 0...boxEdits.length) {
		final editEv = boxEdits[i];

		if (position < editEv.time)
			continue;

		final nextEditEv = boxEdits[i + 1];

		final ease = CoolUtil.flxeaseFromString(editEv.params[0].tweenName, '') ?? FlxEase.linear;
		final tweenDur = Math.max(0.0001, editEv.params[0].tweenDur);

		var editPos = position;

		if (nextEditEv != null)
			editPos = Math.min(position, nextEditEv.time);

		final editElapsed = (editPos - editEv.time) * 0.001;
		var dataEdit = editEv.params[0];

		final ratio = ease(Math.min(editElapsed, tweenDur) / tweenDur);

		var lastWidth = box.boxWidth;
		var lastHeight = box.boxHeight;

		if (dataEdit.width != -1)
			box.boxWidth = FlxMath.lerp(box.boxWidth, dataEdit.width, ratio);
		if (dataEdit.height != -1)
			box.boxHeight = FlxMath.lerp(box.boxHeight, dataEdit.height, ratio);

		box.x = FlxMath.lerp(box.x, minusShit(dataEdit.positionX, box.x) + (lastWidth - minusShit(dataEdit.width, lastWidth)) * .5, ratio);
		box.y = FlxMath.lerp(box.y, minusShit(dataEdit.positionY, box.y) + (lastHeight - minusShit(dataEdit.height, lastHeight)) * .5, ratio);
		if (dataEdit.angle != -1)
			box.angle = FlxMath.lerp(box.angle, dataEdit.angle, ratio);
	}

	if (editSoulEvents.length != 0) {
		var finalMode = 'normal';
		var curSpeed = 1;
		var curGrav = 1;
		for (event in editSoulEvents) {
			if (position < event.time)
				continue;

			var params = event.params[0];
			finalMode = params.mode;

			soul.angle = params.groundAngle;
			curSpeed = params.speedMult;
			curGrav = params.gravityMult;
		}
		if (soul.mode != finalMode)
			soul.mode = finalMode;

		if (soul.mode == 'blue')
			soul.behavior.gravityMult = curGrav;

		soul.behavior.speed = curSpeed;
	} else {
		if (soul.mode != 'normal')
			soul.mode = 'normal';
		soul.angle = 0;
	}

	for (blaster in blastersItems) {
		blaster.timePosition = -1;
	}
	for (bone in boneItems) {
		bone.visible = false;
	}
	for (event in events) {
		if (event.type == EVENT_EDIT_PLATFORM
			|| event.type == EVENT_EDIT_BONE
			|| event.type == EVENT_EDIT_BOX
			|| position < event.time)
			continue;
		// blaster
		if (event.type == EVENT_BLASTER) {
			final eventElapsed = (position - event.time) * 0.001;
			if (Blaster.endedByTime(event.params[0], eventElapsed)) {
				continue;
			}
			var blaster:Blaster;

			if (blasterCount < blastersItems.length) {
				blaster = blastersItems[blasterCount];
			} else {
				blaster = new Blaster();
				blaster.dirtyTimeline = true;
				blaster.quiet = true;
				// blaster.quiet = event.params[0].quiet;
				blaster.camera = camUndertale;
				blasters.add(blaster);

				blastersItems.push(blaster);
			}
			var paramsCopy = Reflect.copy(event.params[0]);
			paramsCopy.initialPosition = FlxPoint.get(paramsCopy.initialPositionX, paramsCopy.initialPositionY);
			paramsCopy.attackPosition = FlxPoint.get(paramsCopy.attackPositionX, paramsCopy.attackPositionY);

			blaster.setup(paramsCopy);
			blaster.start();
			blaster.timePosition = eventElapsed;
			blasterCount++;
		}
		// bone
		else if (event.type == EVENT_BONE) {
			var editEvs = [];

			for (edEv in editBoneEvents) {
				if (edEv == null)
					continue;
				if ((position >= edEv.time) && (edEv.params[0].id == event.params[0].id)) {
					editEvs.push(edEv);
				}
			}

			editEvs.sort(function(a, b) return Reflect.compare(a.time, b.time));

			var bone:Bone;
			var data = event.params[0];
			if (boneCount < boneItems.length) {
				bone = boneItems[boneCount];
			} else {
				bone = new Bone(0, 0, 50, 10);
				bone.moves = false;
				bone.center = true;
				bone.camera = camClipped;
				bones.add(bone);

				boneItems.push(bone);
			}

			bone.indentifier = data.id;
			bone.setPosition(data.positionX, data.positionY);
			bone.boneWidth = data.width;
			bone.boneHeight = data.height;
			bone.visible = true;
			bone.type = data?.mode ?? "normal";

			bone.angle = data.angle;

			bone.velocity.x = data.vX;
			bone.velocity.y = data.vY;
			bone.angularVelocity = data.vA;

			var bonePos = position;

			if (editEvs.length != 0)
				bonePos = Math.min(position, editEvs[0].time);

			final eventElapsed = (bonePos - event.time) * 0.001;

			bone.updateMotion(eventElapsed);

			if (editEvs.length != 0) {
				for (i in 0...editEvs.length) {
					final editEv = editEvs[i];
					final nextEditEv = editEvs[i + 1];

					final lastData = i == 0 ? data : (editEvs[i - 1]);
					final ease = CoolUtil.flxeaseFromString(editEv.params[0].tweenName, '') ?? FlxEase.linear;
					final tweenDur = Math.max(0.0001, editEv.params[0].tweenDur);

					var editPos = position;

					if (nextEditEv != null)
						editPos = Math.min(position, nextEditEv.time);

					final editElapsed = (editPos - editEv.time) * 0.001;

					var dataEdit = editEv.params[0];

					if (dataEdit.positionX != -1)
						bone.x = FlxMath.lerp(bone.x, dataEdit.positionX, ease(Math.min(editElapsed, tweenDur) / tweenDur));
					if (dataEdit.positionY != -1)
						bone.y = FlxMath.lerp(bone.y, dataEdit.positionY, ease(Math.min(editElapsed, tweenDur) / tweenDur));

					if (dataEdit.width != -1)
						bone.boneWidth = FlxMath.lerp(lastData.width, dataEdit.width, ease(Math.min(editElapsed, tweenDur) / tweenDur));
					if (dataEdit.height != -1)
						bone.boneHeight = FlxMath.lerp(lastData.height, dataEdit.height, ease(Math.min(editElapsed, tweenDur) / tweenDur));

					if (dataEdit.vX != -1)
						bone.velocity.x = FlxMath.lerp(lastData.vX, dataEdit.vX, ease(Math.min(editElapsed, tweenDur) / tweenDur));
					if (dataEdit.vY != -1)
						bone.velocity.y = FlxMath.lerp(lastData.vY, dataEdit.vY, ease(Math.min(editElapsed, tweenDur) / tweenDur));
					if (dataEdit.vA != -1)
						bone.angularVelocity = FlxMath.lerp(lastData.vA, dataEdit.vA, ease(Math.min(editElapsed, tweenDur) / tweenDur));
					if (dataEdit.mode != "*last*" || dataEdit.mode != "")
						bone.type = dataEdit?.mode ?? "normal";

					bone.updateMotion(editElapsed);
				}
			}
			boneCount++;
		} else if (event.type == EVENT_PLATFORM) {
			var editEvs = [];

			for (edEv in editPlatformEvents) {
				if (edEv == null)
					continue;
				if ((position >= edEv.time) && (edEv.params[0].id == event.params[0].id)) {
					editEvs.push(edEv);
				}
			}

			editEvs.sort(function(a, b) return Reflect.compare(a.time, b.time));

			var data = event.params[0];

			var platform:Platform;
			if (platformCount < platformsItems.length) {
				platform = platformsItems[platformCount];
			} else {
				platform = new Platform(0, 0, 10, 10);
				platform.thickness = 6;
				platform.moves = false;
				platform.solid = true;
				platform.immovable = true;
				platforms.add(platform);

				platformsItems.push(platform);
			}
			platform.allowCollisions = getGrounds(soul.angle);

			platform.setPosition(data.positionX, data.positionY);
			platform.velocity.x = data.vX;
			platform.velocity.y = data.vY;
			platform.boxWidth = data.width;
			platform.boxHeight = data.height;
			platform.visible = true;

			var platformPos = position;
			if (editEvs.length != 0)
				platformPos = Math.min(position, editEvs[0].time);

			final eventElapsed = (platformPos - event.time) * 0.001;
			platform.updateMotion(eventElapsed);

			if (editEvs.length != 0) {
				for (i in 0...editEvs.length) {
					final editEv = editEvs[i];
					final nextEditEv = editEvs[i + 1];

					final lastData = i == 0 ? data : (editEvs[i - 1]);
					final ease = CoolUtil.flxeaseFromString(editEv.params[0].tweenName, '') ?? FlxEase.linear;
					final tweenDur = Math.max(0.0001, editEv.params[0].tweenDur);

					var editPos = position;

					if (nextEditEv != null)
						editPos = Math.min(position, nextEditEv.time);

					final editElapsed = (editPos - editEv.time) * 0.001;

					var dataEdit = editEv.params[0];
					final ratio = ease(Math.min(editElapsed, tweenDur) / tweenDur);

					if (dataEdit.positionX != -1)
						platform.x = FlxMath.lerp(platform.x, dataEdit.positionX, ratio);
					if (dataEdit.positionY != -1)
						platform.y = FlxMath.lerp(platform.y, dataEdit.positionY, ratio);

					if (dataEdit.width != -1)
						platform.boxWidth = FlxMath.lerp(lastData.width, dataEdit.width, ratio);
					if (dataEdit.height != -1)
						platform.boxHeight = FlxMath.lerp(lastData.height, dataEdit.height, ratio);

					if (dataEdit.vX != -1)
						platform.velocity.x = FlxMath.lerp(lastData.vX, dataEdit.vX, ratio);
					if (dataEdit.vY != -1)
						platform.velocity.y = FlxMath.lerp(lastData.vY, dataEdit.vY, ratio);

					platform.updateMotion(editElapsed);
				}
			}
			platformCount++;
		}
	}

	blasters.update(elapsed);
	bones.update(elapsed);
}

function getGrounds(angle:Float):Int {
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

function addEvent(event) {
	events.push(event);
	switch (event.type) {
		case EVENT_BONE:
			boneEvents.push(event);
		case EVENT_BLASTER:
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

function sortEvents() {
	return;
	events.sort(function(a, b) return Reflect.compare(a.time, b.time));
	boneEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	blasterEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editBoneEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editBoxEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editSoulEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
}
