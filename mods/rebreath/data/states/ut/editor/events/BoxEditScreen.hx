import flixel.FlxG;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIWarningSubstate;

function create() {
	winTitle = "Edit Box Properties";
	winWidth = 700;
}

function postCreate() {
	final params = editorSend.params[0];

	headerText = new UIText(30, 60, FlxG.width, 'Position Data         Event Data', 32);
	add(headerText);

	subHeader = new UIText(30, 110, FlxG.width, 'New Pos & Data (x,y,angle)            Time', 18);
	add(subHeader);

	timeBox = new UITextBox(subHeader.x + 418, subHeader.y + 30, editorSend.time * 0.001, 60, 32);
	add(timeBox);

	commasUp = new UIText(29, subHeader.y + 30 + 10, FlxG.width, '     ,     ,', 18);
	add(commasUp);

	// initial pos data
	posX = new UITextBox(subHeader.x + 2, subHeader.y + 30, params.positionX, 50, 32);
	add(posX);

	posY = new UITextBox(subHeader.x + 2 + 70, subHeader.y + 30, params.positionY, 50, 32);
	add(posY);

	posA = new UITextBox(subHeader.x + 2 + 70 * 2, subHeader.y + 30, params.angle, 50, 32);
	add(posA);

	sizeHeader = new UIText(30, 110 + 82, FlxG.width, 'New Size (Width, Height)', 18);
	add(sizeHeader);

	// size
	widthBox = new UITextBox(subHeader.x + 2, subHeader.y + 110, params.width, 50, 32);
	add(widthBox);

	heightBox = new UITextBox(subHeader.x + 2 + 70, subHeader.y + 110, params.height, 50, 32);
	add(heightBox);

	paramsTest = new UIText(30, 250 + 40, 400, 'Motion Parameters', 32);
	add(paramsTest);

	subParams = new UIText(30, 250 + 60 + 40, FlxG.width, 'Tween Duration   Tween Ease Name', 18);
	add(subParams);

	noteTxt = new UIText(185, 250
		+ 4, 500,
		'Default Properties:\n'
		+ '\nX: '
		+ constBoxX
		+ '\nY: '
		+ constBoxY
		+ '\nWidth: '
		+ constBoxWidth
		+ '\nHeight :'
		+ constBoxHeight, 18);
	noteTxt.alignment = 'right';
	add(noteTxt);

	tweenDur = new UITextBox(subHeader.x + 2, subParams.y + 30, params.tweenDur, 50, 32);
	add(tweenDur);

	tweenEase = new UITextBox(subHeader.x + 2 + 185, subParams.y + 30, params.tweenName, 100, 32);
	add(tweenEase);

	saveButton = new UIButton(winWidth - 200 - 10, winHeight - 80 - 10, 'Add', () -> {
		windowOutput = {
			row: getRow(),
			type: EVENT_EDIT_BOX,
			time: parse(timeBox.label.text, 0) * 1000,
			params: [
				{
					positionX: parse(posX.label.text, 0),
					positionY: parse(posY.label.text, 0),
					angle: parse(posA.label.text, 0),
					width: parse(widthBox.label.text, 0),
					height: parse(heightBox.label.text, 0),
					tweenDur: parse(tweenDur.label.text, 0),
					tweenName: tweenEase.label.text
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
