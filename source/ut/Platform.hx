package ut;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.group.FlxGroup;
import flixel.util.FlxDirectionFlags;
import ut.core.interfaces.ICollidable;
import ut.core.util.CollisionUtil;
import ut.core.util.OrientationUtil;

class Platform extends FlxSprite {
	/**
	 * The actual box container. (the black part)
	 */
	@:noCompletion
	var _container:PlatformElement;

	@:noCompletion
	var _updateSize:Bool = true;

	var hasSeen:Bool = false;

	public var thickness:Float = 10;

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

	public function new(x:Float, y:Float, width:Float, height:Float) {
		super();

		@:bypassAccessor
		this.boxWidth = width;
		@:bypassAccessor
		this.boxHeight = height;

		_container = new PlatformElement();
		_container.makeGraphic(Std.int(boxWidth), Std.int(boxHeight), 0xFF000000);
		_container.solid = false;

		makeGraphic(Std.int(boxWidth), Std.int(boxHeight), 0xFFFFFFFF);
		updateHitbox();

		immovable = true;
		solid = true;
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

private class PlatformElement extends FlxSprite {
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
