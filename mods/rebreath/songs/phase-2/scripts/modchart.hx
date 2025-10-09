return;
import modchart.Manager;

var modchart:Manager;

function postCreate() {
	modchart = new Manager();
	add(modchart);

	setupEvents();
}

var pattern1 = [0, 3, 4, 7, 8, 11, 12, 13, 14, 15, 15.25, 15.5, 15.75, 16];

var pattern2 = [
	 0,  1,  2,  2.5,  3,
	 4,  5,  6,  6.5,  7,
	 8,  9, 10, 10.5, 11,
	12, 13, 14, 14.5, 15
];

function setupEvents() {
	modchart.addModifier('drunk');
	modchart.addModifier('tipsy');
	modchart.addModifier('beat');
	modchart.addModifier('invert');
	modchart.addModifier('opponentSwap');
	modchart.addModifier('drunk');

	ease(0, 32, 'expoOut', '1, beat');

	for (j in 0...2) {
		for (i in pattern1) {
			if (i + 16 * j >= 30)
				break;
			jump(i + 16 * j, 2);
		}
	}
	ease(0, 24, 'cubeOut', '1, drunk');
	ease(7.5, 1, 'cubeOut', '
        1, reverse,
        -0.75, invert,
        0.25, flip,
        360, confusionOffset,
    ');
	ease(11, 1, 'cubeOut', '
        0, reverse,
        1, invert,
        0, flip,
        0, confusionOffset
    ');
	ease(14, 2, 'cubeOut', '0, invert');

	ease(16 + 8, 1, 'cubeOut', '1, opponentSwap');
	ease(16 + 8 + 4, 1, 'cubeOut', '0, opponentSwap');

	ease(29, 1, 'cubeOut', '
        2, tipsySpeed,
        1, tipsy,
        0, beat
    ');

	set(32, '1, beat, 1, flash');
	ease(32, 2, 'cubeOut', '0, flash, 1, tipsySpeed');

	for (j in 0...2) {
		for (i in pattern2) {
			if ((i + 32 + 16 * j) >= 28 + 32)
				break;
			jump(i + 16 * j + 32, 2);
		}
	}

	ease(28 + 32, 1, 'cubeOut', '
        2, tipsySpeed,
        1, tipsy,
        0, beat,
        0.5, opponentSwap,
        360, confusionOffset
    ');
	ease(30 + 32, 1, 'cubeOut', '
        0, confusionOffset,
        1, reverse
');
	set(32 + 32, '1, beat, 1, flash');
	ease(32 + 32, 2, 'cubeOut', '0, flash, 1, tipsySpeed, 0, reverse, 0, confusionOffset, 0, opponentSwap');
}

var j = 1;

function jump(beat, length) {
	set(beat, j + ', tipsy, ' + j * 40 + ', x');
	ease(beat, length, 'cubeOut', '0, tipsy, 0, x');

	j *= -1;
}

function ease(beat, len, ease, args) {
	var fArgs = StringTools.trim(args.toString()).split(',');
	while (fArgs.length > 0) {
		var perc = Std.parseFloat(fArgs.shift());
		var mod = StringTools.trim(fArgs.shift());
		modchart.ease(mod, beat, len, perc, Reflect.field(FlxEase, ease));
	}
}

function set(beat, args) {
	var fArgs = StringTools.trim(args.toString()).split(',');
	while (fArgs.length > 0) {
		var perc = Std.parseFloat(fArgs.shift());
		var mod = StringTools.trim(fArgs.shift());
		modchart.set(mod, beat, perc);
	}
}
