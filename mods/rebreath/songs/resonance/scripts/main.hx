var skipt;
var rt = 0;

function postCreate()
{
    skipt = new FlxText();
    skipt.text = 'Press SPACE to skip the tutorial...';
    skipt.setFormat(Paths.font("determination-mono.ttf"), 32, 0xFFFFFF);
    skipt.screenCenter(FlxAxes.X);
    skipt.y = FlxG.height * 0.75;
    skipt.cameras = [camHUD];
    add(skipt);
}
function update(elapsed)
{
    rt += 90 * elapsed;
    skipt.alpha = 1 - Math.sin(rt * Math.PI / 180); 
}