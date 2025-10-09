import modchart.Manager;

var fm:Manager;
function create()
{
    introLength = 0;
}
function postCreate()
{
	add(fm = new Manager());

	addMod = fm.addModifier;
	set = fm.set;
	ease = fm.ease;
	setV = fm.setPercent;
	getV = fm.getPercent;
	node = fm.node;
	repeater = fm.repeater;  
    
    modchart();
}
function modchart()
{
    addMod('transform');
    addMod('opponentSwap');
    addMod('drunk');
    addMod('vibrate');
    setV('alpha', 0);
    setV('vibrate', 0.3, 0);
    setV('drunkSpeed', -0.5);

    ease('alpha', 48 - 16, 15, 1);

    node(['bop'], ['scale', 'dark'], (p) -> {
        return [p[0] * 0.5, p[0] * 0.5];
    });

    // strums shit
    var alt = 1;
    for (i in 0...4)
    {
        var m = 'y' + Std.string(i);
        var d = 'dark' + Std.string(i);
        var c = 'confusionOffsetZ' + Std.string(i);
        var c2 = 'confusionOffsetX' + Std.string(i);

        var b = 81 + 4 * i;
        ease(m, b, 0.5, -20, FlxEase.quartOut, 0);
        ease(m, b + 0.5, 2, FlxG.height, FlxEase.cubeIn, 0);

        set(d, b, 0.5, 0);
        ease(d, b, 2, 0, FlxEase.cubeOut, 0);

        ease(c, b + 0.5, 2, 90 * alt, FlxEase.cubeIn, 0);
        ease(c2, b + 0.5, 2, -180 * alt, FlxEase.cubeIn, 0);

        alt *= -1;
    }
    ease('opponentSwap', 81 + 4 * 4, 8, 0.5, FlxEase.cubeOut);
    ease('confusonOffsetZ', 81 + 4 * 4, 8, 360, FlxEase.cubeOut);

    set('bop', 104, 1);
    ease('bop', 104, 1, 0, FlxEase.cubeOut);
}
function onCountdown(e)
    e.cancel();