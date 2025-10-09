// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D

// end of ShadertoyToFlixel header

// Hash function for noise 
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// Simple 3D noise function
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    
    float n = p.x + p.y * 157.0 + 113.0 * p.z;
    return mix(mix(mix(hash(n +   0.0), hash(n +   1.0), f.x),
                   mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                   mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

// Fractal Brownian Motion to create more complex noise patterns
float fbm(vec3 p) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    
    // More octaves = more detail
    for(int i = 0; i < 5; i++) {
        sum += noise(p * freq) * amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    
    return sum;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Get normalized texture coordinates
    vec2 uv = fragCoord / iResolution.xy;
    
    // Heat parameters - keeping them exactly as before
    float heatStrength = 0.125; 
    float heatSpeed = 1.0;     
    float heatFreq = 10.0;      
    
    // Create more complex noise patterns using FBM
    float noiseX = fbm(vec3(uv * heatFreq, iTime * heatSpeed));
    float noiseY = fbm(vec3(uv * heatFreq + vec2(43.21, 56.78), iTime * heatSpeed * 0.7 + 10.0));
    
    // Add second layer of noise for more complexity
    float noiseX2 = fbm(vec3(uv * heatFreq * 2.0 + vec2(123.45, 78.90), iTime * heatSpeed * 1.3));
    float noiseY2 = fbm(vec3(uv * heatFreq * 2.0 + vec2(87.65, 43.21), iTime * heatSpeed * 0.9 + 5.0));
    
    // Mix noise layers
    float finalNoiseX = mix(noiseX, noiseX2, 0.5);
    float finalNoiseY = mix(noiseY, noiseY2, 0.5);
    
    // Calculate distortion offset - now applies to entire screen
    vec2 offset = vec2(
        (finalNoiseX * 2.0 - 1.0) * heatStrength, 
        (finalNoiseY * 2.0 - 1.0) * heatStrength
    );

    vec2 distortedUV = clamp(uv + offset, 0.0, 1.0);
    vec4 texColor = texture(iChannel0, distortedUV);
    
    fragColor = texColor;
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}