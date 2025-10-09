import flixel.text.FlxText;
import funkin.backend.scripting.events.CamMoveEvent;

var singX = 0;
var singY = 0;

var followX = 0;
var followY = 0;

public var movementAmount = 75;

function postUpdate(elapsed)
{
    if (curBeat < 0)
        return;

    singX = CoolUtil.fpsLerp(singX, 0, 0.0175);
    singY = CoolUtil.fpsLerp(singY, 0, 0.0175);

    camFollow.setPosition(followX + singX, followY + singY);
}
function onNoteHit(e)
{
    if (!e.player)
        return;

    var n = e.direction;

    singX = ((n == 0) ? -1 : (n == 3 ? 1 : 0)) * movementAmount;
    singY = ((n == 1) ? 1 : (n == 2 ? -1 : 0)) * movementAmount;
}
function onCameraMove(e)
{
    followX = e.position.x;
    followY = e.position.y;
}