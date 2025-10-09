importScript('data/core/ZoomEvents');
importScript('data/core/Cinematic');
importScript('data/core/SoloCam');

function create()
{
    borders.ratio = 0;
    
    events = [
        {
            beat: 0,
            zoom: 0.1
        },
        {
            beat: 8,
            zoom: 0.3,
            speed: 0.3
        },
        {
            beat: 16 - 3,
            zoom: 0.5,
            callback: () -> {
                doSoloTween(0.6, Conductor.crochet / (500), FlxEase.expoIn);
            }
        },
        {
            beat: 16 - 1,
            callback: () -> {
                boyfriend.playAnim('hey');
            }
        },
        {
            beat: 16,
            zoom: 0,
            speed: 1,
            hudZooming: true,
            zooming: true,
            interval: 4,
            callback: () -> {
                doBorderTween(0.2, Conductor.crochet / 250);
                doSoloTween(0, Conductor.crochet / (1000));
            }
        },
        {
            beat: 32,
            zoom: 0.1,
            zooming: false
        },
        {
            beat: 36,
            zoom: 0.2,
            speed: 2.25
        },
        {
            beat: 40,
            zoom: 0.3,
            callback: () -> doSoloTween(0.9, Conductor.crochet / (250 / 3.75))
        },
        {
            beat: 44,
            zoom: 0.4
        },
        {
            beat: 46,
            zoom: 0.5
        },
        {
            beat: 47.75,
            zoom: 0,
            callback: () -> doSoloTween(0, Conductor.crochet / 500)
        },
        {
            beat: 49,
            speed: 1,
            zooming: true
        }
    ];
}