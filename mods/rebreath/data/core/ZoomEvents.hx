import funkin.backend.system.Conductor;
import Float;

var curZoom = 0;
var curSpeed = 1;
var curZooming = false;
var curHUDZooming = false;

public var events = [];

function update(elapsed)
{
    // Prevent default cam zooming
    camZooming = false;
    
    for (event in events)
    {
        if ((event.step != null && Conductor.curStepFloat >= event.step) || (event.beat != null && Conductor.curBeatFloat >= event.beat)) {
            // ?? operator dont work on hscript, sadly

            // El zoom que se va a hacer
            if (event.zoom != null)
                curZoom = event.zoom;

            // La velocidad en la que el zoom sera aplicado
            if (event.speed != null)
                curSpeed = event.speed;

            // Auto zoom por beat (o por el intervalo)
            if (event.zooming != null)
                curZooming = event.zooming;

            // Auto zoom pero en el hud
            if (event.hudZooming != null)
                curHUDZooming = event.hudZooming;

            // Intervalo de beats del zoom (si el auto zoom esta activado)
            if (event.interval != null)
                curInterval = event.interval;

            // Callback custom
            if (event.callback != null)
                event.callback();
            
            events.remove(event);
        }
    }

    camera.zoom = CoolUtil.fpsLerp(camera.zoom, defaultCamZoom + curZoom, 0.05 * curSpeed);
    camHUD.zoom = CoolUtil.fpsLerp(camHUD.zoom, 1, 0.035);

    if (Conductor.curBeatFloat >= 0 && (curZooming || curHUDZooming))
    {
        var f = Conductor.curBeatFloat;
        
        beatProg = f - lastBeat;

        if (beatProg >= curInterval) {
            if (curZooming)
                camera.zoom += 0.02 * camZoomingStrength;
            if (curHUDZooming)
                camHUD.zoom += 0.05 * camZoomingStrength;
            
            lastBeat = f;
            beatProg = 0;
        }
    }
}
var curInterval = 4;
var beatProg = 4;
var lastBeat = 0;