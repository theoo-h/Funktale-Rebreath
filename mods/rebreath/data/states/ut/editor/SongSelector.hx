import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIState;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITextBox;

function create() {
	winTitle = "Switch Song";
	winWidth = 450;
	winHeight = 250;
}

function postCreate() {
	headerText = new UIText(30, 50, 400, 'Song Data', 32);
	add(headerText);

	subHeader = new UIText(30, 95, FlxG.width, 'Name', 18);
	add(subHeader);

	songNameBox = new UITextBox(subHeader.x + 2, subHeader.y + 30, songName, 150, 32);
	add(songNameBox);

	saveButton = new UIButton(winWidth - 120 - 10, winHeight - 80 - 10, 'Switch', () -> {
		songName = songNameBox.label.text;
		var s = new UIState();
		s.scriptName = "ut/AttackEditor";
		FlxG.switchState(s);
		close();
	}, 120, 80);
	saveButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	saveButton.color = 0xFF40C900;
	add(saveButton);

	cancelButton = new UIButton(winWidth - 120 - 20 - 60, winHeight - 80 - 10 + 18 + 30, 'Cancel', () -> {
		close();
	}, 60, 30);
	cancelButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	cancelButton.color = 0xffa50000;
	add(cancelButton);
}
