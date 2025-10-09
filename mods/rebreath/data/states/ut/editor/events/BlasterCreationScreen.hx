import flixel.FlxG;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITextBox;

function create() {
	winTitle = "Create and add a Gaster Blaster";
	winWidth = 700;
}

function postCreate() {
	final params = editorSend.params[0];

	headerText = new UIText(30, 60, 400, 'Position Data', 32);
	add(headerText);

	subHeader = new UIText(30, 110, FlxG.width, 'Initial Data (x,y,angle)    End Data (x,y,angle)', 18);
	add(subHeader);

	commasUp = new UIText(29, subHeader.y + 30 + 10, FlxG.width, '     ,     ,                     ,     ,', 18);
	add(commasUp);

	// initial pos data
	iPosX = new UITextBox(subHeader.x + 2, subHeader.y + 30, params.initialPositionX, 50, 32);
	add(iPosX);

	iPosY = new UITextBox(subHeader.x + 2 + 70, subHeader.y + 30, params.initialPositionY, 50, 32);
	add(iPosY);

	iPosA = new UITextBox(subHeader.x + 2 + 70 * 2, subHeader.y + 30, params.initialAngle, 50, 32);
	add(iPosA);

	// end/attack pos data
	ePosX = new UITextBox(subHeader.x + 309, subHeader.y + 30, params.attackPositionX, 50, 32);
	add(ePosX);

	ePosY = new UITextBox(subHeader.x + 309 + 70, subHeader.y + 30, params.attackPositionY, 50, 32);
	add(ePosY);

	ePosA = new UITextBox(subHeader.x + 309 + 70 * 2, subHeader.y + 30, params.attackAngle, 50, 32);
	add(ePosA);

	paramsTest = new UIText(30, 215, 360, 'Motion Parameters', 32);
	add(paramsTest);

	subParams = new UIText(30, 250 + 15, FlxG.width, 'Intro Dur. Await Dur. Prepare Dur. Hold Dur.  Builder Spd', 18);
	add(subParams);

	// motion params
	inDur = new UITextBox(subParams.x + 2, subParams.y + 30, params.introDuration, 50, 32);
	add(inDur);

	awDur = new UITextBox(subParams.x + 2 + 118, subParams.y + 30, params.awaitDuration, 50, 32);
	add(awDur);

	prepDur = new UITextBox(subParams.x + 2 + 240, subParams.y + 30, params.prepareDuration, 50, 32);
	add(prepDur);

	holdDur = new UITextBox(subParams.x + 2 + 381, subParams.y + 30, params.holdDuration, 50, 32);
	add(holdDur);

	bdrSpd = new UITextBox(subParams.x + 2 + 502, subParams.y + 30, params.builderSpeed, 50, 32);
	add(bdrSpd);

	paramsTest = new UIText(30, 365, 400, 'Event Data  Extra', 32);
	add(paramsTest);

	subParams2 = new UIText(30, 390 + 25, FlxG.width, 'Time                 Scale (x, y)', 18);
	add(subParams2);

	timeBtn = new UITextBox(subParams.x + 2, subParams.y + 32 + 30 + 120, editorSend.time * 0.001, 100, 32);
	add(timeBtn);

	quietCheck = new UICheckbox(30, winHeight - 40 - 10, 'Quiet (no sound)', params.quiet);
	add(quietCheck);

	pointTo = new UICheckbox(30 + quietCheck.width + 180, winHeight - 40 - 10, 'Point Soul', params.pointTo);
	add(pointTo);

	scaleX = new UITextBox(subParams2.x + 2 + 240 - 8, subParams2.y + 30, params?.scaleX ?? 1, 50, 32);
	add(scaleX);

	scaleY = new UITextBox(subParams2.x + 2 + 310, subParams2.y + 30, params?.scaleY ?? 1, 50, 32);
	add(scaleY);

	saveButton = new UIButton(winWidth - 200 - 10, winHeight - 80 - 10, 'Add', () -> {
		windowOutput = {
			row: getRow(),
			type: EVENT_BLASTER,
			time: parse(timeBtn.label.text, 0) * 1000,
			params: [
				{
					initialPositionX: parse(iPosX.label.text, 0),
					initialPositionY: parse(iPosY.label.text, 0),
					initialAngle: parse(iPosA.label.text, 0),
					attackPositionX: parse(ePosX.label.text, 0),
					attackPositionY: parse(ePosY.label.text, 0),
					attackAngle: parse(ePosA.label.text, 0),
					introDuration: parse(inDur.label.text, 0.8),
					awaitDuration: parse(awDur.label.text, 0.05),
					prepareDuration: parse(prepDur.label.text, 0.25),
					holdDuration: parse(holdDur.label.text, 0),
					builderSpeed: parse(bdrSpd.label.text, 1),
					scaleX: parse(scaleX.label.text, 1),
					scaleY: parse(scaleY.label.text, 1),
					quiet: quietCheck.checked,
					pointTo: pointTo.checked
				}
			]
		};
		close();
	}, 200, 80);
	saveButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	saveButton.color = 0xFFA59400;
	add(saveButton);

	resetValuesButton = new UIButton(winWidth - 200 - 20 - 60, winHeight - 80 - 10 + 10, 'Reset', () -> {
		timeBtn.label.text = iPosX.label.text = iPosY.label.text = iPosA.label.text = ePosX.label.text = ePosY.label.text = ePosA.label.text = inDur.label.text = awDur.label.text = prepDur.label.text = holdDur.label.text = bdrSpd.label.text = '';
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
