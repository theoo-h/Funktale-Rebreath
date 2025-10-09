//
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISubstateWindow;

var blasterButton:UIButton;
var boneAddButton:UIButton;
var boneMotionButton:UIButton;

function create() {
	winTitle = "Add Attack or Event";
}

var height = 35;

function postCreate() {
	blasterButton = new UIButton(winWidth * .05, 50, 'Add Blaster', () -> {
		editorSend = BLASTER_TEMPLATE();
		nextWindow = 'ut/editor/events/BlasterCreationScreen';
		close();
	}, winWidth * .9, height);
	blasterButton.autoAlpha = false;
	add(blasterButton);

	boneAddButton = new UIButton(winWidth * .05, blasterButton.y + blasterButton.bHeight + 10, 'Add Bone', () -> {
		editorSend = BONE_TEMPLATE();
		nextWindow = 'ut/editor/events/BoneCreationScreen';
		close();
	}, winWidth * .9, height);
	boneAddButton.autoAlpha = false;
	add(boneAddButton);

	boneMotionButton = new UIButton(winWidth * .05, boneAddButton.y + boneAddButton.bHeight + 10, 'Edit Bone Motion', () -> {
		editorSend = EDIT_BONE_TEMPLATE();
		nextWindow = 'ut/editor/events/EditBoneMotionScreen';
		close();
	}, winWidth * .9, height);
	boneMotionButton.autoAlpha = false;
	add(boneMotionButton);

	boxEdit = new UIButton(winWidth * .05, boneMotionButton.y + boneMotionButton.bHeight + 10, 'Edit Box', () -> {
		editorSend = BOX_EDIT_TEMPLATE();
		nextWindow = 'ut/editor/events/BoxEditScreen';
		close();
	}, winWidth * .9, height);
	boxEdit.autoAlpha = false;
	add(boxEdit);

	soulEdit = new UIButton(winWidth * .05, boxEdit.y + boxEdit.bHeight + 10, 'Edit Soul', () -> {
		editorSend = EDIT_SOUL_TEMPLATE();
		nextWindow = 'ut/editor/events/EditSoulScreen';
		close();
	}, winWidth * .9, height);
	soulEdit.autoAlpha = false;
	add(soulEdit);

	platformAdd = new UIButton(winWidth * .05, soulEdit.y + soulEdit.bHeight + 10, 'Add Platform', () -> {
		editorSend = PLATFORM_TEMPLATE();
		nextWindow = 'ut/editor/events/PlatformCreationScreen';
		close();
	}, winWidth * .9, height);
	platformAdd.autoAlpha = false;
	add(platformAdd);

	platformEdit = new UIButton(winWidth * .05, platformAdd.y + platformAdd.bHeight + 10, 'Edit Platform', () -> {
		editorSend = EDIT_PLATFORM_TEMPLATE();
		nextWindow = 'ut/editor/events/EditPlatformScreen';
		close();
	}, winWidth * .9, height);
	platformEdit.autoAlpha = false;
	add(platformEdit);

	dialogBox = new UIButton(winWidth * .05, platformEdit.y + platformEdit.bHeight + 10, 'Dialogue Box', () -> {
		editorSend = EDIT_PLATFORM_TEMPLATE();
		nextWindow = 'ut/editor/events/DialogueBoxScreen';
		close();
	}, winWidth * .9, height);
	dialogBox.autoAlpha = false;
	add(dialogBox);

	cancelButton = new UIButton(winWidth * .05, winHeight - 60 - 15, 'Cancel', () -> {
		close();
	}, winWidth * .9, 60);
	cancelButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	cancelButton.color = 0xffa50000;
	add(cancelButton);
}
