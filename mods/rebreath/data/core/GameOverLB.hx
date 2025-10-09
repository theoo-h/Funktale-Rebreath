import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.FlxCamera.FlxCameraFollowStyle;

var deathText:FlxSprite;

var spawnDelay = 1;
var tmer = 0;
var spawned = 0;

var camOver:FlxCamera = new FlxCamera();

var tProg = 0;
var black = new FlxSprite();

var d = new FlxText();
function create(ev)
{
    ev.cancel();

    FlxG.cameras.add(camOver, false);
    camOver.bgColor = 0x00000000;
    cameras = [camOver];

    black.makeGraphic(FlxG.width * 5, FlxG.height * 5, 0xFF000000);
    black.screenCenter();
    black.alpha = 0;
    add(black);

    deathText = new FlxSprite();
    deathText.loadGraphic(Paths.image('ut/death/death_text'));
    deathText.updateHitbox();
    deathText.screenCenter(FlxAxes.X);
    deathText.clipRect = new FlxRect(0, 0, deathText.width, deathText.height);
    deathText.offset.y = -100;
    add(deathText);

    d.text = '';
    d.size = 16;
    add(d);

    game.persistentDraw = true;
}
var trans = 0;
function update(elapsed)
{
    var ut = game.player.extra.get('camUndertale') != null && game.player.extra.get('camUndertale').visible;
    var target = ut ? game.player.extra.get('soul') : game.boyfriend;
    var cam = ut ? game.player.extra.get('camUndertale') : game.camGame;
    var offset = ut ? FlxPoint.get() : game.boyfriend.cameraOffset;

    cam.targetOffset = offset;

    cam.follow(target, FlxCameraFollowStyle.NO_DEAD_ZONE, 0.05);
    cam.zoom = CoolUtil.fpsLerp(cam.zoom, 1.3, 0.05);
    game.camHUD.alpha = CoolUtil.fpsLerp(game.camHUD.alpha, 0, 0.125);

    if ((offset.x + offset.y) == 0)
        offset.put();

    if (trans <= 1)
    {
        trans += elapsed;
        camOver.visible = false;

        return;
    }
    
    if (spawned < 2)
    {
        tmer += elapsed;

        if (tmer >= spawnDelay) {
            tmer = 0;
            spawned++;
        }
    }

    tProg = FlxMath.lerp(tProg, 1, 0.125 * 60 * elapsed);
    black.alpha = tProg;

    deathText.clipRect.height = spawned * (deathText.height * .5);
    deathText.clipRect = deathText.clipRect;
}