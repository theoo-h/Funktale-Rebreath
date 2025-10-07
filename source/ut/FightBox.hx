package ut;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.group.FlxGroup;
import flixel.util.FlxDirectionFlags;
import ut.core.util.CollisionUtil;
import ut.core.util.OrientationUtil;

class FightBox extends FlxSprite {
	static inline final COLLIDER_WIDTH:Float = 20;

	/**
	 * The actual box container. (the black part)
	 */
	@:noCompletion
	var _container:BoxElement;

	@:noCompletion
	var _updateSize:Bool = true;

	public var thickness:Float = 10;

	public var guest:Soul;

	public var dirtyColliders:Bool = true;

	public var boxWidth(default, set):Float;
	public var boxHeight(default, set):Float;

	function set_boxWidth(Value:Float) {
		_updateSize = true;

		return boxWidth = Value;
	}

	function set_boxHeight(Value:Float) {
		_updateSize = true;

		return boxHeight = Value;
	}

	public function new(?guest:Soul) {
		super();

		if (guest != null)
			this.guest = guest;

		_container = new BoxElement();
		_container.makeGraphic(Constants.BATTLE_FIGHT_BOX_WIDTH, Constants.BATTLE_FIGHT_BOX_HEIGHT, 0xFF000000);
		_container.solid = false;

		makeGraphic(Constants.BATTLE_FIGHT_BOX_WIDTH, Constants.BATTLE_FIGHT_BOX_HEIGHT, 0xFFFFFFFF);
		updateHitbox();

		@:bypassAccessor
		boxWidth = width;

		@:bypassAccessor
		boxHeight = height;

		solid = false;
	}

	public function updateCollision():Array<FlxDirectionFlags> {
		final groundFlags:Array<FlxDirectionFlags> = OrientationUtil.getGrounds(angle, guest.angle);
		final collisionWalls:Array<FlxDirectionFlags> = CollisionUtil.aabbCollision(guest, _container, angle, guest.mode == BLUE, groundFlags);

		// reset grounded to false
		guest.grounded = false;
		// then collide with the box walls
		for (dir in collisionWalls) {
			if (groundFlags.contains(dir)) {
				guest.grounded = true;
				break;
			}
		}

		return collisionWalls;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (_updateSize) {
			this.setGraphicSize(Std.int(boxWidth), Std.int(boxHeight));
			this.updateHitbox();

			_container.setGraphicSize(Std.int(this.width - thickness), Std.int(this.height - thickness));
			_container.updateHitbox();
		}

		_container.setPosition(this.x + thickness * .5, this.y + thickness * .5);
		_container.angle = this.angle;

		_updateSize = false;
	}

	override function draw() {
		checkEmptyFrame();

		var didDraw = false;

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		for (camera in cameras) {
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			didDraw = true;

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		if (didDraw)
			_container.draw();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
}

private class BoxElement extends FlxSprite {
	override function draw() {
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		for (camera in cameras) {
			if (!camera.visible || !camera.exists)
				continue;

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);
		}
	}
}

private class BoxCollider extends FlxObject {
	public var direction:FlxDirectionFlags;
}
