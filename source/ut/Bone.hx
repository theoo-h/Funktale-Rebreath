package ut;

/**
	* An Undertale Sans Bone
	  totally functional and
	  customizable.
	* Copyright (C) 2023-2024 Theo
 */
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import ut.core.BoneGroup;
import ut.core.interfaces.ICollidable;
import ut.core.util.OBBCollision;

/**
 * Bone Modes Abstract
 */
enum abstract BType(String) from String {
	final NORMAL:String = 'normal';
	final BLUE:String = 'blue';
	final ORANGE:String = 'orange';
}

class Bone extends FlxTypedSpriteGroup<FlxSprite> implements ICollidable {
	/**
	 * Current bone Type
	 */
	public var type(default, set):BType = NORMAL;

	private function set_type(_value:BType):BType {
		type = _value;

		color = COLORS.get(_value) ?? COLORS.get(NORMAL);

		return type;
	}

	public var center:Bool = false;

	/**
		* Default Bone Colors
		 
		* You can override this to
		  change the default bone
		  color.
	 */
	public static var DEFAULT_COLORS:Map<BType, FlxColor> = [NORMAL => 0xFFFFFF, BLUE => 0x00edFF, ORANGE => 0xFFa925];

	/**
		* Bone Colors
		* Defined by `DEFAULT_COLORS`

		* You can override this to
		   change the colors for
		   each mode.
	 */
	public var COLORS:Map<BType, FlxColor> = DEFAULT_COLORS;

	/**
		* Default Hitsound Volume

		* You can override this to
		  change default hitsound vol.
		  for every bone.
	 */
	public inline static var DEFAULT_HITSOUND_VOLUME:Float = 0.4;

	public var HITSOUND_VOLUME:Float = DEFAULT_HITSOUND_VOLUME;

	public inline static var DEFAULT_BONE_BORDER_WIDTH:Float = 10;

	public var boneBorderWidth:Float = DEFAULT_BONE_BORDER_WIDTH;

	/**
	 * Sprites
	 */
	private var left:BoneFrag;

	private var body:BoneFrag;
	private var right:BoneFrag;

	public var hitbox:FlxObject;
	public var collidable:Bool;

	/**
	 * Bone Width
	 */
	public var boneWidth:Float = 35;

	/**
	 * Bone Height
	 */
	public var boneHeight:Float = 15;

	private var _hitsound:FlxSound;

	public var parent:BoneGroup;

	var lastW:Float = -1;
	var lastH:Float = -1;

	var _sinA:Float = 0;
	var _cosA:Float = 0;

	public var indentifier:String;
	public var hasSeen:Bool = false;

	override function set_angle(nA:Float):Float {
		super.set_angle(nA);

		_sinA = Math.sin(nA * FlxAngle.TO_RAD);
		_cosA = Math.cos(nA * FlxAngle.TO_RAD);

		return angle = nA;
	}

	public function new(x:Float, y:Float, bWidth:Float, bHeight:Float) {
		super(x, y);

		boneWidth = bWidth;
		boneHeight = bHeight;

		body = new BoneFrag(x, y);
		body.loadGraphic(Paths.image('ut/bone/body'));
		add(body);

		left = new BoneFrag(x, y);
		left.loadGraphic(Paths.image('ut/bone/tail'));
		add(left);

		right = new BoneFrag(x, y);
		right.loadGraphic(Paths.image('ut/bone/tail'));
		right.flipX = true;
		add(right);

		hitbox = new FlxObject();

		angle = 0;

		updateBone();

		collidable = true;
	}

	public function updateBone():Void {
		var sin = Math.sin(body.angle * Math.PI / 180);
		var cos = Math.cos(body.angle * Math.PI / 180);

		var width = Math.max(boneBorderWidth * 2, boneWidth);

		body.setGraphicSize(Std.int(width - boneBorderWidth * 2), Std.int(boneHeight));
		body.updateHitbox();

		final mp:FlxPoint = body.getMidpoint();

		var off = boneBorderWidth;

		if (center)
			body.setPosition(x + off - boneWidth * .5, y - boneHeight * .5);
		else
			body.setPosition(x + off, y);

		var off2 = (width - boneBorderWidth - 1) * .5;

		left.angle = right.angle = body.angle;
		// left corner
		left.setGraphicSize(Std.int(boneBorderWidth), Std.int(boneHeight));
		left.updateHitbox();

		left.setPosition(mp.x - left.width * .5 - off2 * cos, mp.y - left.height * .5 - off2 * sin);

		// right corner
		right.setGraphicSize(Std.int(boneBorderWidth), Std.int(boneHeight));
		right.updateHitbox();

		right.setPosition(mp.x - right.width * .5 - off2 * -cos, mp.y - right.height * .5 - off2 * -sin);

		hitbox.setSize(Std.int(boneWidth - (boneBorderWidth * 2)), Std.int(boneHeight * .4));

		hitbox.angle = body.angle;
		hitbox.x = mp.x - hitbox.width * .5;
		hitbox.y = mp.y - hitbox.height * .5;
		mp.put();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (_delay > 0)
			_delay -= elapsed;
		else if (_delay < 0)
			_delay = 0;

		updateBone();

		lastW = boneWidth;
		lastH = boneHeight;
	}

	/**
	 * POOLING HANDLER
	 */
	override public function kill():Void {
		super.kill();
	}

	public function resolveCollision(object:ICollidable) {
		return ((type == NORMAL)
			|| (type == ORANGE && object.collidable)
			|| (type == BLUE && !object.collidable))
			&& OBBCollision.check(hitbox, object.hitbox);
	}

	var _delay:Float = .0;

	public function hitsound(?vol:Float = -1) {
		if (_delay > 0)
			return;
		if (vol == -1)
			vol = HITSOUND_VOLUME;

		if (_hitsound != null)
			_hitsound.time = 0;
		else
			_hitsound = FlxG.sound.play(Paths.sound('ut/bone'), vol);

		_delay = 0.05;
	}
}

typedef BoneFrag = FlxSprite;
