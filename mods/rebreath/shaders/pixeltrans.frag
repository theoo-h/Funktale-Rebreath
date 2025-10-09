// modificated from https://www.shadertoy.com/view/MfjyRw

#pragma header

#define threshold 0.55
#define padding 0.05

#define CELLS 100.0
#define STEPS 100.0
#define COLOR1 vec3(0, 0, 0)
#define COLOR2 vec3(0.2, 0.2, 0.2)
#define STROKE_WIDTH .05
#define STROKE_OPACITY .15
uniform float transitionProgress;

vec2 ratio(vec2 ps) {
	float x = ps.x;
	float y = ps.y;
	vec2 ratio = vec2(1, 1);
	if (x > y)
		ratio = vec2(1, y / x);
	else if (y > x)
		ratio = vec2(y / x, 1);
	return ratio;
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec3 getRandomColor() {
    // random shit lol
    float randValue = fract(sin(transitionProgress + dot((openfl_TextureCoordv*openfl_TextureSize).xy, vec2(5.9898,20.233))) * 4378.5453);
    
    if (randValue < 0.9) {
        return vec3(0.0);  // black
    } else {
        return vec3(0.2, 0.2, 0.2);  // gray
    }
}

void mainImage( out vec4 fragColor )
{
    float cellSize = 1.0 / CELLS;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 nUv = openfl_TextureCoordv;
    
    vec4 tex = flixel_texture2D(bitmap, nUv);
   
    float progress = (transitionProgress + 1. + (1. / CELLS)) * 0.5;
    
    vec2 sUv = fract(nUv * (1. / cellSize));

    float distToEdge = min(min(sUv.x, 1. - sUv.x), min(sUv.y, 1. - sUv.y));
		float strokeFactor = smoothstep(STROKE_WIDTH - 0.05 * STROKE_WIDTH, STROKE_WIDTH + 0.05 * STROKE_WIDTH, distToEdge);
    
    vec2 pUv = nUv;
    
    pUv -= mod(pUv, cellSize);
		
    float stepProgress = mod(progress, 1. / cellSize);
    float fadeProgress = abs(pUv.y - 0.5) + stepProgress;
    fadeProgress = pow(fadeProgress, 5.);
    float fadeProgress2 = pow(fadeProgress, 2.);
    float fadeProgress3 = pow(fadeProgress2, 2.);
    float fadeProgress4 = pow(fadeProgress3, 2.);

    // pattern
    float r = max(0.07, random(pUv));
    float p = 1. - step(fadeProgress, r);
    float p2 = 1. - step(fadeProgress2, r);
    float p3 = 1. - step(fadeProgress3, r);
    float p4 = 1. - step(fadeProgress4, r);
    
    float rt = mix(p2, p3, stepProgress);

    vec3 colorRan = getRandomColor();
    vec3 pColor = mix(COLOR2, colorRan, p3);
    
    // Output to screen
    fragColor = vec4(mix(tex.rgb, pColor, p2), flixel_texture2D(bitmap, openfl_TextureCoordv).a);
    fragColor.xyz += mix(vec3(1.), vec3(0.), strokeFactor) * (p) * (1. - p4) * STROKE_OPACITY;

    // chroma key lol
    if (fragColor.g > 0.4) {
        fragColor.rgb = vec3(fragColor.r, 0.0, fragColor.b);
        fragColor.a = 0.0;
    }
}

void main() {
	mainImage(gl_FragColor);
}