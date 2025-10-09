return;
import lime.app.Application;
import openfl.system.Capabilities;

function onEvent(event) {
	if (event.event.name == "windowHit" && !winMove) {
		winMove = true;
		xDir = 0;
		yDir = 0;
		switch (event.event.params[0]) {
			case 'izquierda':
				xDir = -1;
			case 'derecha':
				xDir = 1;
			case 'arriba':
				yDir = -1;
			case 'abajo':
				yDir = 1;
		}
		trace(event.event.params[0]);
		trace(xDir);
		trace(yDir);
		updateTarget();
	}
}

var xDir = 0;
var yDir = 0;
var winProgress = 0;
var lastWinMove = false;
var winMove = false;
var window = Application.current.window;
var winX = window.x;
var winY = window.y;
var lastShaking = false;
var shaking = false;
var shakeProgress = 1;
var targetX = 0;
var targetY = 0;

function updateTarget() {
	if (xDir != 0)
		targetX = xDir > 0 ? Capabilities.screenResolutionX - FlxG.stage.window.width - 2 : 2;
	if (yDir != 0)
		targetY = yDir > 0 ? Capabilities.screenResolutionY - FlxG.stage.window.height - 2 - 50 : 2 + 30;
}

function update(e) {
	if (FlxG.keys.justPressed.I && !winMove)
		winMove = true;

	if (winMove) {
		if (lastWinMove != winMove) {
			FlxG.sound.play(Paths.sound('ut/snd_b'));
			winX = window.x;
			winY = window.y;
		}
		final eased = FlxEase.expoIn(winProgress);

		if (targetX != 0)
			window.x = FlxMath.lerp(winX, targetX, Math.min(1, eased));
		if (targetY != 0)
			window.y = FlxMath.lerp(winY, targetY, Math.min(1, eased));

		if (winProgress < 1)
			winProgress += e * 1.5;
		else {
			winProgress = 0;
			winMove = false;
			shaking = true;

			FlxG.sound.play(Paths.sound('ut/snd_impact'));
		}
	}

	if (shaking) {
		if (lastShaking != shaking) {
			winX = window.x;
			winY = window.y;
		}

		if (shakeProgress <= 0) {
			shakeProgress = 1;
			shaking = false;
			window.x = winX;
			window.y = winY;
			return;
		}

		window.x = winX + (Math.random() * shakeProgress * 17);
		window.y = winY + (Math.random() * shakeProgress * 17);
		shakeProgress -= e * 4;
	}

	lastShaking = shaking;
	lastWinMove = winMove;
}

function destroy() {
	window.x = (Capabilities.screenResolutionX * .5) - (FlxG.stage.window.width * .5);
	window.y = (Capabilities.screenResolutionY * .5) - (FlxG.stage.window.height * .5);
}
