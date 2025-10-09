var SOLO_SPRITE:FlxSprite;

var tween:FlxTween;

public var soloSprite = {
    alpha: 0
};

function postCreate()
{
    SOLO_SPRITE = new FlxSprite();
    SOLO_SPRITE.makeSolid(FlxG.width * 5, FlxG.height * 6, 0xFF000000);
    SOLO_SPRITE.screenCenter();
    SOLO_SPRITE.scrollFactor.set();
    SOLO_SPRITE.shader = null;
    insert(members.indexOf(boyfriend) - 1, SOLO_SPRITE);
}

function update(e)
{
    SOLO_SPRITE.alpha = soloSprite.alpha;

    if (JUDGEMENT_LIGHTNING != null) {
        JUDGEMENT_LIGHTNING.alpha = FlxMath.bound(0.3 - soloSprite.alpha, 0, 0.3);
        JUDGEMENT_FRONT_PILLARS.alpha = FlxMath.bound(1 - soloSprite.alpha * 0.6, 0, 1);
    }
}
public function doSoloTween(alpha, speed, ?ease)
{
    if (ease == null)
        ease = FlxEase.expoOut;

    if (tween != null)
        tween.cancel();

    tween = FlxTween.tween(soloSprite, { alpha: FlxMath.bound(alpha, 0, 1) }, speed, { ease: ease });
}