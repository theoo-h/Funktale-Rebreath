package ut;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import ut.core.interfaces.ICollidable;
import ut.core.util.OBBCollision;

// enum abstract BlasterAttackState(String) from String {}

typedef BlasterConfig = {
	/**
	 * Starting position when the blaster enters.
	 */
	initialPosition:Null<FlxPoint>,

	/**
	 * Starting angle when the blaster enters.
	 */
	initialAngle:Null<Float>,

	/**
	 * Target position where the blaster will attack.
	 */
	attackPosition:Null<FlxPoint>,

	/**
	 * Final angle the blaster will face when attacking.
	 */
	attackAngle:Null<Float>,

	/**
	 * Time it takes for the blaster to move in (acts like entry speed).
	 */
	introDuration:Null<Float>,

	/**
	 * Idle time after arriving before preparing to attack.
	 */
	awaitDuration:Null<Float>,

	/**
	 * Duration of the mouth opening and squash/stretch animation.
	 */
	prepareDuration:Null<Float>,

	/**
	 * Time the beam stays active before the blaster exits.
	 */
	holdDuration:Null<Float>,

	/**
	 * Speed multiplier for the exit motion after holding.
	 */
	builderSpeed:Null<Float>,

	/**
	 * Scale X
	 */
	scaleX:Null<Float>,

	/**
	 * Scale Y
	 */
	scaleY:Null<Float>
}

class Blaster extends FlxTypedGroup<FlxSprite> implements ICollidable {
	public static final BASE_SCALE:Float = 4;
	public static final BASE_BEAM_SCALE_X:Float = 4;

	public inline static var DEFAULT_HITSOUND_VOLUME:Float = 1;
	public inline static var DEFAULT_LAZER_VOLUME:Float = 0.7;

	public var HITSOUND_VOLUME:Float = DEFAULT_HITSOUND_VOLUME;
	public var LAZER_VOLUME:Float = DEFAULT_LAZER_VOLUME;

	private var _hitsound:FlxSound;

	public var config:Null<BlasterConfig> = null;
	public var running:Bool = false;
	public var dirtyTimeline:Bool = false;

	public var centerOffset:Bool = true;
	public var quiet:Bool = false;

	private var head:FlxSprite;
	private var beam:FlxSprite;

	private var headState:Int = 0;
	private var lastHeadState:Int = 0;

	private var attackState:String = "";
	private var lastAttackState:String = "";

	private var timePosition(default, set):Float = 0;
	private var lastTimePosition:Float = -1;

	function set_timePosition(value:Float):Float {
		return timePosition = Math.max(0, value);
	}

	public var hitbox:FlxObject;
	public var collidable:Bool;

	public var useless:Bool = false;

	public function setup(config:BlasterConfig) {
		// dispose the old config
		if (this.config != null) {
			this.config?.initialPosition?.put();
			this.config?.attackPosition?.put();
		}
		this.config = __validateConfig(config);

		if (head == null) {
			head = new FlxSprite();
			head.loadGraphic(Paths.image("ut/blaster/head0"));
			head.scale.scale(4);
			head.updateHitbox();

			add(head);
		}

		if (beam == null) {
			beam = new FlxSprite();
			beam.loadGraphic(Paths.image("ut/blaster/beam"));
			beam.scale.set(4, 4);
			beam.updateHitbox();

			beam.alpha = 0.0001;
			add(beam);
		}

		if (hitbox == null) {
			hitbox = new FlxObject();
			collidable = true;
		}

		head.visible = beam.visible = false;
	}

	public function resolveCollision(object:ICollidable) {
		return collidable && OBBCollision.check(beam, object.hitbox);
	}

	public function start() {
		running = true;
		head.visible = beam.visible = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (running && !dirtyTimeline)
			timePosition += elapsed;

		final time = timePosition;
		final cfg = config;

		if (time > 0) {
			if (time < cfg.introDuration)
				__updateIntro(time / cfg.introDuration);
			else if (time < cfg.introDuration + cfg.awaitDuration)
				__updateAwait();
			else if (time < cfg.introDuration + cfg.awaitDuration + cfg.prepareDuration)
				__updatePrepare((time - cfg.introDuration - cfg.awaitDuration) / cfg.prepareDuration);
			else
				__updateAttack((time - cfg.introDuration - cfg.awaitDuration - cfg.prepareDuration) * cfg.builderSpeed);

			__updatePositions();
			__updateStateChanges();
		} else {
			head.visible = beam.visible = false;
			attackState = "";
			collidable = false;
		}

		if (_delay > 0)
			_delay -= elapsed;
		else if (_delay < 0)
			_delay = 0;

		final mp = beam.getMidpoint();
		hitbox.setSize(beam.width, beam.height);
		hitbox.angle = beam.angle;
		hitbox.setPosition(mp.x - hitbox.width / 2, mp.y - hitbox.height / 2);

		mp.put();
	}

	/**
	 * internal stuff
	 */
	function __validateConfig(data:BlasterConfig):BlasterConfig {
		if (data.initialPosition == null)
			data.initialPosition = FlxPoint.get();
		if (data.initialAngle == null)
			data.initialAngle = 0;
		if (data.attackPosition == null)
			data.attackPosition = FlxPoint.get();
		if (data.attackAngle == null)
			data.attackAngle = 0;
		if (data.introDuration == null)
			data.introDuration = 0.8;
		if (data.awaitDuration == null)
			data.awaitDuration = 0.05;
		if (data.prepareDuration == null)
			data.prepareDuration = 0.25;
		if (data.holdDuration == null)
			data.holdDuration = 0;
		if (data.builderSpeed == null)
			data.builderSpeed = 1;
		if (data.scaleX == null)
			data.scaleX = 1;
		if (data.scaleY == null)
			data.scaleY = 1;
		return data;
	}

	function __updateIntro(ratio:Float) {
		attackState = "Intro";

		ratio = FlxEase.expoOut(ratio);
		final cfg = config;

		head.setPosition(FlxMath.lerp(cfg.initialPosition.x, cfg.attackPosition.x, ratio), FlxMath.lerp(cfg.initialPosition.y, cfg.attackPosition.y, ratio));
		head.angle = FlxMath.lerp(cfg.initialAngle, cfg.attackAngle, ratio);
		beam.alpha = 0.0001;
		beam.scale.x = 4 * config.scaleX;
		beam.scale.y = 0;
		head.scale.x = 4 * config.scaleY;
		head.scale.y = 4 * config.scaleX;
		headState = 0;
		collidable = false;
		useless = false;
	}

	function __updateAwait() {
		attackState = "Await";
		head.setPosition(config.attackPosition.x, config.attackPosition.y);
		head.angle = config.attackAngle;
		beam.alpha = 0.0001;
		beam.scale.x = 4 * config.scaleX;
		head.scale.y = 4 * config.scaleX;
		head.scale.x = 4 * config.scaleY;
		headState = 0;
		collidable = false;
		useless = false;
	}

	function __updatePrepare(ratio:Float) {
		attackState = "Preparing";
		head.setPosition(config.attackPosition.x, config.attackPosition.y);
		head.angle = config.attackAngle;

		final squish = (4 - roundedExpDip(ratio) * 0.25) * config.scaleY;
		beam.scale.x = 4 * config.scaleX;
		head.scale.x = squish;
		head.scale.y = 4 * config.scaleX;

		headState = Std.int(FlxEase.quartInOut(Math.min(1, ratio)) * 3);

		if (ratio >= 0.85) {
			attackState = "Opening";
			beam.scale.y = 1 * config.scaleY;
			beam.alpha = 0.2;
		} else {
			beam.scale.y = 0;
			beam.alpha = 0.0001;
		}

		collidable = false;
		useless = false;
	}

	function __updateAttack(timeElap:Float) {
		final cfg = config;
		final leaveElapsed = Math.max(0, timeElap - cfg.holdDuration);
		final moveAmount = Math.pow(leaveElapsed, 4) * 600;

		final angleRad = cfg.attackAngle * Math.PI / 180;
		final cos = FlxMath.fastCos(angleRad);
		final sin = FlxMath.fastSin(angleRad);

		attackState = leaveElapsed == 0 ? "Attacking" : "Attack Leave";

		head.setPosition(cfg.attackPosition.x - moveAmount * cos, cfg.attackPosition.y - moveAmount * sin);
		head.angle = cfg.attackAngle;

		final fade = 1 - FlxMath.bound(Math.pow(leaveElapsed, 4), 0, 1);
		final bounce = cfg.holdDuration == 0 ? 0.8 : Math.abs(Math.cos((timeElap - 0.25) * 1.25 * Math.PI));

		beam.scale.x = 4 * config.scaleX;
		head.scale.x = config.scaleY * (3.76 + FlxEase.quintOut(Math.min(1, timeElap * 4)) * 0.25);
		head.scale.y = 4 * config.scaleX;
		headState = Std.int(4 + Math.min(1, timeElap * 40) - 2 * FlxMath.bound((1 - fade) * 2, 0, 1));
		beam.scale.y = config.scaleY * ((2 + FlxEase.quintOut(Math.min(1, timeElap * 2.5)) * 2 - 0.7 + bounce * 1.5) * fade);
		beam.alpha = (0.3 + FlxEase.quintOut(Math.min(1, timeElap * 5)) * 0.7 * (0.75 + bounce * 0.25)) * fade;

		collidable = fade > 0.1;
		useless = Math.abs(fade) <= 0.001;
	}

	public var HEAD_BEAM_SEPARATION:Float = 22;

	function __updatePositions() {
		head.angle -= 90;
		beam.angle = head.angle + 90;

		head.x -= head.width * .5;
		head.y -= head.height * .5;

		final mid = head.getMidpoint();
		final angleRad = beam.angle * Math.PI / 180;
		final cos = FlxMath.fastCos(angleRad);
		final sin = FlxMath.fastSin(angleRad);
		final offset = HEAD_BEAM_SEPARATION * beam.scale.x;

		beam.updateHitbox();
		beam.x = mid.x + cos * (beam.width * 0.5 + offset) - beam.width * 0.5;
		beam.y = mid.y + sin * (beam.width * 0.5 + offset) - beam.height * 0.5;

		mid.put();
	}

	function __updateStateChanges() {
		if (!quiet && lastAttackState != attackState) {
			switch (attackState) {
				case "Intro":
					FlxG.sound.play(Paths.sound("ut/blaster_start"), LAZER_VOLUME);
				case "Opening":
					FlxG.sound.play(Paths.sound("ut/blaster_shoot"), LAZER_VOLUME);
			}
		}
		if (lastHeadState != headState) {
			head.loadGraphic(Paths.image('ut/blaster/head' + headState));
			head.updateHitbox();
		}
		lastAttackState = attackState;
		lastHeadState = headState;
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

	// easing shit for smoother attack
	function expState(t:Float):Float {
		return t < 0.5 ? FlxEase.circOut(t * 2) : FlxEase.circOut(1 - (t - 0.5) * 2);
	}

	function roundedExpDip(t:Float):Float {
		return t < 0.5 ? FlxEase.circOut(t * 2) : FlxEase.circOut(1 - (t - 0.5) * 1.5);
	}

	public static function calcBlasterMaxTime(cfg:BlasterConfig):Float {
		var intro = cfg.introDuration ?? 0.8;
		var await = cfg.awaitDuration ?? 0.05;
		var prepare = cfg.prepareDuration ?? 0.25;
		var hold = cfg.holdDuration ?? 0;
		var builderSpeed = cfg.builderSpeed ?? 1;

		var fadeTime = Math.pow(0.999, 0.25);

		var totalTime = (intro + await + prepare + hold + fadeTime) / builderSpeed;
		return totalTime;
	}

	public static function isUseless(cfg:BlasterConfig, time:Float):Bool {
		return time > calcBlasterMaxTime(cfg);
	}
}
