package ut.core.interfaces;

import flixel.FlxObject;

interface ICollidable {
	public var hitbox:FlxObject;
	public var collidable:Bool;

	public function resolveCollision(object:ICollidable):Bool;
}
