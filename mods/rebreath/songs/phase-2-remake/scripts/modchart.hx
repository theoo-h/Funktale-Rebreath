import modchart.Config;
import modchart.Manager;

var modchart:Manager = new Manager();

function create()
{
	add(modchart);

	trace('mc');

	addMod = modchart.addModifier;
	eadd = modchart.add;
	ease = modchart.ease;
	set = modchart.set;
	setVal = modchart.setPercent;
	getVal = modchart.getPercent;

	setupModchart();
}

function setupModchart()
{
	Config.RENDER_ARROW_PATHS = true;
	Config.ARROW_PATHS_CONFIG.RESOLUTION = 2.5;

	setVal('arrowPathThickness', 5);
	setVal('arrowPathAlpha', 0);

	addMod('localRotate');
	addMod('transform');
	addMod('tipsy');
	addMod('drunk');

	setVal('confusionOffsetY', 25, 0);
	setVal('localRotateY', 25, 0);

	setVal('localRotateY', -25, 1);
	setVal('confusionOffsetY', -25, 1);

	setVal('drunkPeriod', 1.25);

	var side = 1;
	for (i in 0...32)
	{
		var drunky = 4 * i;
		var length = 4;

		eadd('tipsy', drunky, length, 1.5 * side, ease_pop);
		eadd('drunk', drunky, length, 1.5 * side, ease_pop);
		eadd('arrowPathAlpha', drunky, length, 1, ease_pop);

		eadd('confusionOffsetZ', drunky, length, 360 * side, FlxEase.backOut);

		side = side * -1;
	}
}

// eases
function ease_pop(t)
{
	return 3.5 * (1 - t) * (1 - t) * Math.sqrt(t);
}
