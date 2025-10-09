// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iAmount;
#define iChannel0 bitmap
#define texture flixel_texture2D

// variables which are empty, they need just to avoid crashing shader
uniform vec4 iMouse;

// end of ShadertoyToFlixel header

const float pi = 4.0 * atan(1.0);
const float ang = (3.0 - sqrt(5.0)) * pi;
const float gamma = 1.8;
const float SAMPLES = 150.0;
const float BRIGHT_SPOT_TRESHOLD = 0.5;

vec3 BriSp(vec3 p) {
    if (p.x + p.y + p.z > BRIGHT_SPOT_TRESHOLD * 3.0)
        p = (1.0 / (1.0 - p) - 1.0) * (1.0 - BRIGHT_SPOT_TRESHOLD);
    p = clamp(p, 0.0, 100.0);
    return p;
}

vec3 getBaseColor(vec2 uv) {
    vec3 col = texture(iChannel0, uv).rgb;
    col = BriSp(col);
    return col;
}

vec3 bokeh(vec2 uv, vec2 radius, float lod) {
    vec3 col = vec3(0.0);
    for (float i = 0.0; i < SAMPLES; i++) {
        float d = i / SAMPLES;
        vec2 offset = vec2(sin(ang * i), cos(ang * i)) * sqrt(d) * radius;
        vec3 sampleCol = getBaseColor(uv + offset);
        col += pow(sampleCol, vec3(gamma));
    }
    return pow(col / SAMPLES, vec3(1.0 / gamma));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 pix = 1.0 / iResolution.xy;

    float r = iAmount;
    r *= r * 20.0;
    if (iMouse.z > 0.0) r = iMouse.x / iResolution.y * 100.;

    float lod = log2(r / SAMPLES * pi * 5.0);

    vec3 col = bokeh(uv, r * pix, lod);

    fragColor = vec4(col, texture(iChannel0, fragCoord / iResolution.xy).a);

    if (SAMPLES == 0.0)
        fragColor = vec4(getBaseColor(uv), 1.0);
}


void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}