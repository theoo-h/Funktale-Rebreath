package ut.core;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxPool.IFlxPool;
import haxe.io.Bytes;

class UndertaleObject extends FlxSprite
{
    /**
     * Hitbox Container
      
     * Width:  `hitRatioX`
     * Height: `hitRatioY`
     * 
     * Position: Center of `this`
     */
    public var hitbox:UndertaleHitbox;

    /**
     * Hitbox pixels Width and Height
     
     * Whetever this value is changed,
       the value of `hitRatioX` and `hitRatioY`
       will be the same value of `hitRatio`
     */
    public var hitRatio(default, set):Null<Int>;

	@:noCompletion
    private function set_hitRatio(value:Null<Int>):Null<Int>
    {
        hitRatio = hitRatioX = hitRatioY = value;

        return hitRatio;
    }

    /**
     * Hitbox width
      
     * Changing `hitRatio`
       value will change
       this value 
     */
    public var hitRatioX:Null<Int>;

    /**
     * Hitbox height
      
     * Changing `hitRatio`
       value will change
       this value 
     */
    public var hitRatioY:Null<Int>;

    // for pools
    public var initializated:Bool = false;

	  public function new(?x:Float = 0, ?y:Float = 0, ?graphic:FlxGraphicAsset)
    {
        super(x, y, graphic);

        antialiasing = false;
        pixelPerfectRender = false;
        pixelPerfectPosition = true;
    }

    /**
     * Initializates the `hitbox`
     */
    public function createHitbox():Void
    {
        if (hitRatioX == null || hitRatioY == null) hitRatio = Std.int(width / 2);

        hitbox = new UndertaleHitbox(x, y, hitRatioX, hitRatioY);
        updateHitRect();
    }

    /**
     * Update `hitbox` size
       and position.
     */
    public function updateHitRect()
    {
        hitbox.x = (x + width / 2) - hitRatioX / 2;
        hitbox.y = (y + height / 2) - hitRatioY / 2;
        hitbox.setSize(hitRatioX, hitRatioY);
    }

    override function update(elapsed:Float)
    {
        if (hitbox != null) updateHitRect();

        super.update(elapsed);
    }

    /**
      * Checks if an object
        and `this` are colliding.
    
      * @param object  The object  / player
      * @return If the sprites are colliding 
    */
    public function __checkCollide(object:UndertaleObject):Bool
    {
        return FlxG.overlap(object.hitbox, this);
    }

    /**
      * Checks if 2 objects (rects)
        are colliding
    
      * @param object  The object  / player
      * @param collide The collide / projectile
      * @return If the sprites are colliding 
    */
    public static function checkCollide(object:UndertaleObject, collide:UndertaleObject):Bool
    {
        return FlxG.overlap(object.hitbox, collide.hitbox);
    }
}

typedef UndertaleHitbox = FlxObject;

interface IUndertaleObject extends IFlxPool<UndertaleObject>
{
    public function get():UndertaleObject;
    public function preAllocate(numObjects:Int):Void;
    public function clear():Array<UndertaleObject>;
}

class RenderArea extends FlxShader
{
    @:glFragmentSource('
        #ifdef GL_ES
        precision mediump float;
        #endif

        varying vec2 vTexCoord;
        uniform sampler2D uTexture;
        uniform float ratioX;
        uniform float ratioY;

        void main() {
        vec2 texCoord = vTexCoord * vec2(ratioX, ratioY);
        if(texCoord.x >= 0.0 && texCoord.x <= 1.0 && texCoord.y >= 0.0 && texCoord.y <= 1.0) {
            gl_FragColor = texture2D(uTexture, vTexCoord * vec2(ratioX, ratioY));
        } else {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
        }
    }
    ')

    public function new()
    {
        super();
    }
}