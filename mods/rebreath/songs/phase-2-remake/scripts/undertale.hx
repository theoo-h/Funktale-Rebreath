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

	canRegen = false;

	generateGradient = true;
	gradientColor = 0xBE0D8D9E;
	gradientAlpha = 0.85;

	undertale = false;
}

function onUndertaleSetupPost()
{
	soul.mode = 'blue';
}
