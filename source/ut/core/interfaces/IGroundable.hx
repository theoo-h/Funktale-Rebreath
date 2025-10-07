package ut.core.interfaces;

interface IGroundable {
	public var grounded(default, set):Bool;

	function set_grounded(value:Bool):Bool;
}
