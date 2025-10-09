import flixel.FlxG;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIWarningSubstate;

function create() {
	winTitle = "Edit Soul Properties";
	winWidth = 700;
	winHeight = 400;
}

function postCreate() {
	final params = editorSend.params[0];

	headerText = new UIText(30, 60, FlxG.width, 'Soul Properties', 32);
	add(headerText);

	subHeader = new UIText(30, 110, FlxG.width, 'Mode       Ground Angle   Gravity Mult   Movement Speed', 18);
	add(subHeader);

	commasUp = new UIText(29, subHeader.y + 30 + 10, FlxG.width, '       ,', 18);
	add(commasUp);

	final list = ['normal', 'blue'];
	modeBox = new UIDropDown(subHeader.x, subHeader.y + 30, 135, 32, list, list.indexOf(params.mode));
	add(modeBox);

	groundAngleBox = new UITextBox(subHeader.x + 2 + 120, subHeader.y + 30, params.groundAngle, 50, 32);
	add(groundAngleBox);

	gravMult = new UITextBox(subHeader.x + 2 + 120 + 165, subHeader.y + 30, params.gravityMult, 80, 32);
	add(gravMult);

	movSpeed = new UITextBox(subHeader.x + 2 + 120 + 330, subHeader.y + 30, params.speedMult, 80, 32);
	add(movSpeed);

	headerText2 = new UIText(30, 215, FlxG.width, 'Event Data', 32);
	add(headerText2);

	subHeader2 = new UIText(30, headerText2.y + 110 - 60, FlxG.width, 'Time', 18);
	add(subHeader2);

	timeBox = new UITextBox(subHeader2.x, subHeader2.y + 30, editorSend.time * 0.001, 100, 32);
	add(timeBox);

	saveButton = new UIButton(winWidth - 200 - 10, winHeight - 80 - 10, 'Add', () -> {
		windowOutput = {
			row: getRow(),
			type: EVENT_EDIT_SOUL,
			time: parse(timeBox.label.text, 0) * 1000,
			params: [
				{
					mode: modeBox.options[modeBox.index],
					groundAngle: parse(groundAngleBox.label.text, 0),
					gravityMult: parse(gravMult.label.text, 1),
					speedMult: parse(movSpeed.label.text, 1)
				}
			]
		};
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
