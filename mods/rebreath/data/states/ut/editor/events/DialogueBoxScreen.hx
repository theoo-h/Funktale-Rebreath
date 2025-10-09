import flixel.FlxG;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIWarningSubstate;

function create() {
	winTitle = "Add dialogue event";
	winWidth = 700;
}

function postCreate() {
	final params = editorSend.params[0];

	headerText = new UIText(30, 60, FlxG.width, 'Dialogue Data', 32);
	add(headerText);

	subHeader = new UIText(30, 110, FlxG.width, 'Text            Time', 18);
	add(subHeader);

	timeBox = new UITextBox(subHeader.x + 418, subHeader.y + 30, editorSend.time * 0.001, 60, 32);
	add(timeBox);

	commasUp = new UIText(29, subHeader.y + 30 + 10, FlxG.width, '     ,     ,', 18);
	add(commasUp);

	// initial pos data
	textBox = new UITextBox(subHeader.x + 2, subHeader.y + 30, '', 300, 100, true);
	add(textBox);

	sizeHeader = new UIText(30, 110 + 150, FlxG.width, 'Parameters', 18);
	add(sizeHeader);

	// size
	speedBox = new UITextBox(subHeader.x + 2, subHeader.y + 110, params.width, 50, 32);
	add(speedBox);

	saveButton = new UIButton(winWidth - 200 - 10, winHeight - 80 - 10, 'Add', () -> {
		windowOutput = {};
		close();
	}, 200, 80);
	saveButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	saveButton.color = 0xFFA59400;
	add(saveButton);

	resetValuesButton = new UIButton(winWidth - 200 - 20 - 60, winHeight - 80 - 10 + 10, 'Reset', () -> {
		timeBox.label.text = posX.label.text = posY.label.text = posA.label.text = velX.label.text = velY.label.text = velA.label.text = accX.label.text = accY.label.text = accA.label.text = dragX.label.text = dragY.label.text = dragA.label.text = '';
	}, 60, 30);
	resetValuesButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	add(resetValuesButton);

	cancelButton = new UIButton(winWidth - 200 - 20 - 60, winHeight - 80 - 10 + 18 + 30, 'Cancel', () -> {
		if (!editingEvent)
			nextWindow = 'ut/editor/EventPicker';
		close();
	}, 60, 30);
	cancelButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	cancelButton.color = 0xffa50000;
	add(cancelButton);
}

function parse(num, defValue) {
	var parsed = Std.parseFloat(num);
	return num == '' || parsed == Math.NaN ? defValue : parsed;
}

function update() {}
