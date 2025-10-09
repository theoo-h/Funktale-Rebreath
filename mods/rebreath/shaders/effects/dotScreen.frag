// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform)
	{
		return color;
	}
	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

// Ruofei Du
// Dot Screen / Halftone: https://www.shadertoy.com/view/4sBBDK
// Halftone: https://www.shadertoy.com/view/lsSfWV

float greyScale(in vec3 col) {
    return dot(col, vec3(0.2126, 0.7152, 0.0722));
}

mat2 rotate2d(float angle){
    return mat2(cos(angle), -sin(angle), sin(angle),cos(angle));
}

float dotScreen(in vec2 uv, in float angle, in float scale) {
    float s = sin( angle ), c = cos( angle );
	vec2 p = (uv - vec2(0.5)) * iResolution.xy;
    vec2 q = rotate2d(angle) * p * scale; 
	return ( sin( q.x ) * sin( q.y ) ) * 4.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 col = texture(iChannel0, uv).rgb; 
    float angle = iMouse.y < 1e-3 ? 0.4 : iMouse.x / iMouse.y;
    float scale = 1.0 + 0.3 * sin(iTime); 
    col = vec3( col * 10.0 - 5.0 + dotScreen(uv, angle, scale) );
    fragColor = vec4(col * 0.5, texture(iChannel0, uv));
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}