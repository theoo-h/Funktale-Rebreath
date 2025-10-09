importScript("data/core/UndertaleHUD.hx");
importScript("data/core/UndertaleMC.hx");
function create()
{
	// player.cpu = true;
}

function onUndertaleSetup()
{
	blastersHurt = true;
	healthDrain *= 1.25;

	generateGradient = false;
	canRegen = false;
}

function beatHit()
{
	if (curBeat == 48)
	{
		undertaleQueue = true;
	}
	if (curBeat == 49)
	{
		undertaleQueue = false;
		undertale = true;

		soul.mode = 'blue';
	}
}
