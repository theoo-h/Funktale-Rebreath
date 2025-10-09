import flixel.FlxSprite;

var transitionSprite:FlxSprite;
static var shader = new CustomShader('pixeltrans');

function create(e)
{
	e.cancel();

	shader.transitionProgress = e.transOut ? -0.65 : 1;

	transitionSprite = new FlxSprite();
	transitionSprite.makeGraphic(FlxG.width, FlxG.height, 0xFF00FF00);
	transitionSprite.alpha = 1;
	add(transitionSprite);
	transitionSprite.shader = shader;

	FlxTween.tween(shader, {transitionProgress: e.transOut ? 1 : -0.65}, e.transOut ? 0.5 : 0.75,
		{onComplete: finish, ease: e.transOut ? FlxEase.cubeOut : FlxEase.cubeInOut});
}
