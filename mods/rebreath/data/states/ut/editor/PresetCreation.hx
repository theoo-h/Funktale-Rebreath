import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITextBox;

function create() {
	winTitle = "Create a Preset";
	winWidth = 500;
	winHeight = 220;
}

function postCreate() {
	headerText = new UIText(30, 50, 400, 'Preset Data', 32);
	add(headerText);

	subHeader = new UIText(30, 95, FlxG.width, 'Identificator', 18);
	add(subHeader);

	idBox = new UITextBox(subHeader.x + 2, subHeader.y + 30, 'Example Preset', 150, 32);
	add(idBox);

	saveButton = new UIButton(winWidth - 200 - 10, winHeight - 80 - 10, 'Add', () -> {
		presetOutput = {
			name: idBox.label.text,
			data: presetInput.data
		}
		close();
	}, 200, 80);
	saveButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	saveButton.color = 0xFFA59400;
	add(saveButton);

	cancelButton = new UIButton(winWidth - 200 - 20 - 60, winHeight - 80 - 10 + 18 + 30, 'Cancel', () -> {
		close();
	}, 60, 30);
	cancelButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	cancelButton.color = 0xffa50000;
	add(cancelButton);
}
