
importScript("data/core/UndertaleHUD.hx");
importScript("data/core/UndertaleMC.hx");

function onUndertaleSetup()
{
    blastersHurt = true;
    healthDrain *= 1.25;

    generateGradient = false;

    canRegen = true;

    onlyUndertale = true;
}
function onUndertaleSetupPost()
{
    soul.mode = 'red';
}
function beatHit()
{
    if (curBeat == -3)
    {
        undertale = true;
        soul.mode = 'blue';
    }    
}

function sideBone(times, interval, bSep, sepY, vel, ox)
{
    var offset = 2;
    var initialY = box.container.y + offset;
    var fullWidth = box.container.height - offset * 2;
    var finalY = initialY + fullWidth;

    for (i in 0...times)
    {
        var scaleR = 0.525;
    
        var sep = sepY;

        var w1 = fullWidth * scaleR;
        var w2 = fullWidth - w1 - sep;
        var h = 25;
        var offX = ox != null ? ox : 0;

        var velocity = vel;

        new FlxTimer().start(interval * i, (_) -> {
            var x = box.x + boxWidth;
            var v = -velocity;

            var blue = createBone(x + offX, initialY + fullWidth / 2, fullWidth, h, 'blue');
            blue.angle = 90;
            blue.velocity.x = v;
            addBone(blue);

            var boneUP = createBone(x + bSep + offX,   initialY + w1 / 2, w1, h, 'normal');
            boneUP.angle = 90;
            boneUP.velocity.x = v;
            addBone(boneUP);

            var boneDOWN = createBone(x + bSep + offX, initialY + w1 + sep + w2 / 2, w2, h, 'normal');
            boneDOWN.angle = 90;
            boneDOWN.velocity.x = v;
            addBone(boneDOWN);
        });

        trace(i);
    }
}
function sideBones(times, interval, sepY, vel, ?rY)
{
    var yInitial = box.y + box.thickness;
    var size = box.height - box.thickness * 2;

    for (i in 0...times)
    {
        var scale = 0.6;
        var boneSeparation = sepY;
        var widthUP = size * scale;
        var widthDOWN = size * (1 - scale) - boneSeparation;

        var velocity = vel;

        new FlxTimer().start(interval * i, (_) -> {
            for (i in 0...2)
            {
                var x = i == 0 ? box.x - 25 : box.x + box.width;
                var v = i == 0 ? velocity : -velocity;

                var boneUP = createBone(
                    x,
                    yInitial + widthUP * 0.5,
                    widthUP,
                    25,
                    'normal'
                );
                boneUP.angle = 90;
                boneUP.velocity.x = v;
                addBone(boneUP);
    
                var boneDOWN = createBone(
                    x,
                    yInitial + widthUP + boneSeparation + widthDOWN * 0.5 - box.thickness,
                    widthDOWN,
                    25,
                    'normal'
                );
                boneDOWN.angle = 90;
                boneDOWN.velocity.x = v;
                addBone(boneDOWN);
            }
        });
    }
}
function boneFile(iX, iY, iA, sX, sY, w, h, len, velx, vely, vela, type, ?au)
{
    var bones = [];
    for (i in 0...len)
    {
        var bone = createBone(iX + sX * i, iY + sY * i, w, h, type);
        bone.angle = iA;
        bone.velocity.set(velx, vely);
        bone.angularVelocity = vela;
        bone.allowAutoDestroy = au;
        addBone(bone);

        bones.push(bone);
    }

    return bones;
}