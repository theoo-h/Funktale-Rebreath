package ut.core;

import flixel.group.FlxGroup.FlxTypedGroup;
import ut.Bone;

// fancy and unnecesary way to make pooling shit
// @:build(ut.core.macros.BoneMacro.buildPooling())
class BoneGroup extends FlxTypedGroup<Bone> {
	override public function new() {
		super();
	}

	override function add(bone:Bone):Bone {
		bone.parent = this;

		return super.add(bone);
	}

	override function insert(position:Int, bone:Bone):Bone {
		bone.parent = this;

		return super.insert(position, bone);
	}

	override function replace(oldBone:Bone, newBone:Bone):Bone {
		oldBone.parent = null;
		newBone.parent = this;

		return super.replace(oldBone, newBone);
	}

	override public function remove(bone:Bone, Splice:Bool = false):Bone {
		bone.parent = null;

		return super.remove(bone, Splice);
	}
}
