#pragma header

uniform vec4 frameUV;

uniform float minX;
uniform float maxX;
uniform float minY;
uniform float maxY;

void main()
{
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
    
if ((openfl_TextureCoordv.x < minX ||
     openfl_TextureCoordv.x > maxX ||
     openfl_TextureCoordv.y < minY ||
     openfl_TextureCoordv.y > maxY) &&
    color.a > 0.0)
{
    gl_FragColor = vec4(0.5, 0.0, 0.0, 0.5);
}
else
{
    gl_FragColor = color;
}
}