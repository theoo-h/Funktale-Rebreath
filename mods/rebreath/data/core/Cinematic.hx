var up:FlxSprite;
var down:FlxSprite;

var tween:FlxTween;

public var DEFAULT_BORDER_POS = 0.15;
public var DEFAULT_BORDER_COLOR = 0xFF000000;

public var borders = {
    ratio: DEFAULT_BORDER_POS
};

function postCreate()
{
    up = new FlxSprite().makeSolid(FlxG.width * 2, FlxG.height, DEFAULT_BORDER_COLOR);
    down = new FlxSprite().makeSolid(FlxG.width * 2, FlxG.height, DEFAULT_BORDER_COLOR);
    up.cameras = down.cameras = [camHUD];

    insert(members.indexOf(strumLines), up);
    insert(members.indexOf(strumLines), down);
}
function update(elapsed)
{
    up.y = FlxG.height / 2 + ((FlxG.height / 2) * (1 - borders.ratio));
    down.y = FlxG.height / 2 - down.height - ((FlxG.height / 2) * (1 - borders.ratio));

    down.screenCenter(FlxAxes.X);
    up.screenCenter(FlxAxes.X);

    up.visible = down.visible = undertale ? false : true;
}
public function doBorderTween(ratio, speed, ?ease)
{
    if (ease == null)
        ease = FlxEase.expoOut;

    if (tween != null)
        tween.cancel();

    tween = FlxTween.tween(borders, { ratio: FlxMath.bound(ratio, 0, up.height) }, speed, { ease: ease });
}