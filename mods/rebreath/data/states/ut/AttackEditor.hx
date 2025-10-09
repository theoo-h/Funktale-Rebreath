/**
 * Functional Attack Editor
 * Features:
 * - Timeline grid with proper scaling, rewind, and fast-forward support.
 * - Add and remove multiple events.
 * - Edit or delete already placed events.
 * - Select one or multiple events, and drag them individually or as a group using selection drag.
 * - Proper visualization of events, attacks, and tweens, regardless of time changes.
 * - Event group/preset system with import and export support.
 * - Undo & Redo system.
 * - Quantization & Snap system.
 * 
 * Expect random bugs or issues while using it, its my first ever editor.
 * @author Theo0p
 */

import Sys;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import funkin.backend.MusicBeatState;
import funkin.backend.assets.Paths;
import funkin.backend.chart.Chart;
import funkin.backend.system.Conductor;
import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.FlxInterpolateColor;
import funkin.editors.SaveSubstate;
import funkin.editors.UndoList;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIButtonList;
import funkin.editors.ui.UIContextMenu;
import funkin.editors.ui.UISliceSprite;
import funkin.editors.ui.UISlider;
import funkin.editors.ui.UISprite;
import funkin.editors.ui.UIState;
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UITopMenu;
import funkin.menus.MainMenuState;
import haxe.Json;
import lime.ui.FileDialog;
import openfl.Assets;
import sys.FileSystem;
import sys.io.File;
import ut.Blaster;
import ut.Bone;
import ut.FightBox;
import ut.Platform;
import ut.Soul;

class EventUI extends FlxSprite
{
	public var data:Dynamic;
	public var selected = false;

	public var dragOnce:Bool = false;

	public var rowPoint = null;
	public var dragPoint = null;

	var _lastScaleOff:Float = 0;
	var from = 0;

	public var scaleOff:Float = 0;
	public var scaleLerped:Float = 0;

	var tweenTmr = 0.;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (tweenTmr < 1)
		{
			tweenTmr += elapsed * 2;
		}
		else if (tweenTmr >= 1)
		{
			tweenTmr = 1;
		}

		scaleLerped = FlxMath.lerp(from, scaleOff, FlxEase.bounceOut(tweenTmr));

		if (_lastScaleOff != scaleOff)
		{
			tweenTmr = 0;
			from = _lastScaleOff;
		}
		_lastScaleOff = scaleOff;
	}
}

class PresetButton extends UIButton
{
	var presetData = null;

	var onDelete = null;
	var onSave = null;

	var deleteButton;
	var deleteIcon;
	var saveButton;
	var saveIcon;

	public function new(newWidth, newHeight, presetData, newCallback)
	{
		this.presetData = presetData;
		var name = Std.string(presetData.name);

		super(0, 0, name, newCallback);
		bWidth = newWidth;
		bHeight = newHeight;
		field.text = name;

		deleteButton = new UIButton(newWidth + 5, 0, '', newHeight, newHeight);
		deleteButton.color = 0xAFFF0000;
		members.push(deleteButton);

		deleteIcon = new FlxSprite().loadGraphic(Paths.image("editors/deleter"));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		saveButton = new UIButton(newWidth + deleteButton.bWidth + 5, 0, '', newHeight, newHeight);
		saveButton.color = 0xFF13A81F;
		members.push(saveButton);

		saveIcon = new FlxSprite().loadGraphic(Paths.image("editors/ui/upload-button"));
		saveIcon.antialiasing = false;
		saveIcon.scale.scale(0.8);
		saveButton.color = 0xFF69FF75;
		saveIcon.updateHitbox();
		members.push(saveIcon);

		deleteButton.callback = () ->
		{
			onDelete(this);
		};
		saveButton.callback = () ->
		{
			onSave(this);
		};
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		deleteButton.selectable = saveButton.selectable = this.selectable;
		deleteIcon.alpha = deleteButton.alpha;
		saveIcon.alpha = saveButton.alpha;
	}

	override function draw()
	{
		follow(deleteButton, this, bWidth + 5, 0);
		follow(deleteIcon, this, bWidth + 5 + (deleteButton.bWidth - deleteIcon.width) * .5, (deleteButton.bHeight - deleteIcon.height) * .5);

		follow(saveButton, this, bWidth + deleteButton.bWidth + 10, -1);
		follow(saveIcon, this, bWidth + saveButton.bWidth + 10 + (saveButton.bWidth - saveIcon.width) * .5, (saveButton.bHeight - saveIcon.height) * .5);

		super.draw();
	}

	function follow(spr:FlxSprite, target:FlxSprite, x:Float = 0, y:Float = 0)
	{
		spr.cameras = target is UISprite ? target.__lastDrawCameras : target.cameras;
		spr.setPosition(target.x + x, target.y + y);
		spr.scrollFactor.set(target.scrollFactor.x, target.scrollFactor.y);
	}
}

static final GRID_SIZE = 30;
static final gridScale = 1;

// constants
static final EVENT_BLASTER = 0x01;
static final EVENT_BONE = 0x02;
static final EVENT_EDIT_BONE = 0x03;
static final EVENT_EDIT_BOX = 0x04;
static final EVENT_EDIT_SOUL = 0x05;
static final EVENT_PLATFORM = 0x06;
static final EVENT_EDIT_PLATFORM = 0x07;
static final EVENT_DIALOGUE_BOX = 0x08;

//
static final GRID_COUNT:Int = 7;
static final BLASTER_ICON_GRAPHIC = 'blaster';
static final BONE_ICON_GRAPHIC = 'bone';
static final EDIT_BONE_ICON_GRAPHIC = 'bone_motion';
static final EDIT_BOX_ICON_GRAPHIC = 'box_edit';
static final EDIT_SOUL_ICON_GRAPHIC = 'soul_edit';
static final PLATFORM_ICON_GRAPHIC = 'platform';
static final EDIT_PLATFORM_ICON_GRAPHIC = 'edit_platform';
static final DIALOGUE_BOX_GRAPHIC = 'dialogue_box';
static final startTime = 0;
static final songName:String = 'phase-1';
static var hoverTime:Float = 0;

static function getEventTime()
{
	// TODO: use Conductor.songPosition instead of GRID_SIZE * 8
	return hoverTime = (uiGridGrabber.visible ? getTimeFromWorldY(uiGridGrabber.y) : getTimeFromWorldY(GRID_SIZE * 8));
}

static function getRow()
{
	return insideGrid ? uiCurrentGridRow : 0;
}

static final DIALOGUE_BOX_TEMAPLE = () ->
{
	return {
		row: getRow(),
		type: EVENT_DIALOGUE_BOX,
		time: getEventTime(),
		params: [
			{
				text: 'Lorem ipsum',
				speed: 0.08,
				sounds: [],
				showStar: false,
				action: 'write' // write and stop
			}
		]
	}
}

static final EDIT_SOUL_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_EDIT_SOUL,
		time: getEventTime(),
		params: [
			{
				mode: 'normal',
				groundAngle: 0,
				gravityMult: 1,
				speedMult: 1
			}
		]
	};
};

static final BOX_EDIT_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_EDIT_BOX,
		time: getEventTime(),
		params: [
			{
				positionX: -1,
				positionY: -1,
				angle: -1,
				width: -1,
				height: -1,
				tweenDur: 0,
				tweenName: 'linear'
			}
		]
	};
};

static final BLASTER_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_BLASTER,
		time: getEventTime(),
		params: [
			{
				id: '',
				initialPositionX: 0,
				initialPositionY: 0,
				initialAngle: 0,
				attackPositionX: 0,
				attackPositionY: 0,
				attackAngle: 0,
				introDuration: 0.8,
				awaitDuration: 0.05,
				prepareDuration: 0.25,
				holdDuration: 0,
				builderSpeed: 1,
				quiet: false,
				pointTo: false,
				scaleX: 1,
				scaleY: 1
			}
		]
	};
};

static final BONE_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_BONE,
		time: getEventTime(),
		params: [
			{
				mode: 'normal',
				id: '',
				positionX: 0,
				positionY: 0,
				angle: 0,
				width: 50,
				height: 20,
				vX: 0,
				vY: 0,
				vA: 0,
				tweenDur: 0,
				tweenName: 'linear',
				out: false
			}
		]
	};
};

static final EDIT_BONE_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_EDIT_BONE,
		time: getEventTime(),
		params: [
			{
				mode: 'normal',
				id: '',
				positionX: -1,
				positionY: -1,
				angle: -1,
				width: -1,
				height: -1,
				vX: -1,
				vY: -1,
				vA: -1,
				tweenDur: 0,
				tweenName: 'linear'
			}
		]
	};
};

static final PLATFORM_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_PLATFORM,
		time: getEventTime(),
		params: [
			{
				id: '',
				positionX: -1,
				positionY: -1,
				width: -1,
				height: -1,
				vX: -1,
				vY: -1
			}
		]
	};
};

static final EDIT_PLATFORM_TEMPLATE = () ->
{
	return {
		row: getRow(),
		type: EVENT_EDIT_PLATFORM,
		time: getEventTime(),
		params: [
			{
				id: '',
				positionX: -1,
				positionY: -1,
				width: -1,
				height: -1,
				vX: -1,
				vY: -1,
				tweenDur: 0,
				tweenName: 'linear'
			}
		]
	};
};

static var windowOutput:Dynamic = null;
static var nextWindow:String = '';
static var editorSend:Dynamic = {};
static var editingEvent = false;
static var editEventIndex:Int = 0;
static var editEventManualIndex:Int = 0;
static var fileEvents = null;

// BULLSHIT FOR PLATFORMS AND BONES
var hashList = [EVENT_BONE => [], EVENT_PLATFORM => []];
var hashPendingEdit = ["a" => 0];

// uhh
var chart:Chart;
var fileDialog = new FileDialog();
var editorWatermark:FlxText;

// ui stuff
var uiCam:FlxCamera;
var uiGroup:FlxGroup;
var topMenuSpr:UITopMenu;
var uiInfoText:FlxText;
var uiEventGrp = null; // song time controller stuff
var uiSongBox:UISliceSprite;
var uiSongRewind:UIButton;
var uiSongForward:UIButton;
var uiSongPause:UIButton;
var uiSongSlider:UISlider;
var uiGridPosition = 0;
var uiPresetBox:UIButtonList;
static var uiGridGrabber:FlxSprite;
var uiEventStart:FlxSprite;
var uiGrids:Array<FlxBackdrop> = [];
static var uiCurrentGridRow:Int = 0;
var uiEventSelecting = false;
var uiSelectionBox:UISliceSprite;
var uiTimeLine:FlxSprite;
var uiContextPopups:Array<UIContextMenuOption>;

// attacks editor
var uiAddButton:UIButton;
var uiAddIcon:FlxSprite;

// song stuff
var music:FlxSound;
var updatingTime:Bool = false;
var musicPaused:Bool = true;

// battle stuff
var camBattle:FlxCamera;
var camBattleClipped:FlxCamera;
var box:FightBox;

// event stuff //
// object arrays
var bones = [];
var blasters = [];
var platforms = [];

// object groups
var boneGrp = new FlxGroup();
var blasterGrp = new FlxGroup();
var platformGrp = new FlxGroup();

// meta events
var events = [];
var blasterEvents = [];
var boneEvents = [];
var editBoneEvents = [];
var editBoxEvents = [];
var editSoulEvents = [];
var platformEvents = [];
var editPlatformEvents = [];

// other
var eventSprites:Array<EventUI> = [];
var curSoulGroundAngle = 0;
var curSoulMode = 'normal';

// presets stuff
static var presetOutput = null;
static var presetInput = null;
var presetQueue = false;
var presetClipboard = null;
static final TEMP_PATH = Paths.getAssetsRoot() + '/data/___tmpAttacks.json';

function create()
{
	trace('[ Loading Attack Editor ]');
	if (FlxG.sound.music != null)
		FlxG.sound.music.stop();
	editorSend = null;

	for (k => v in hashList)
		v = [];
	hashPendingEdit.clear();

	editingEvent = false;
	editEventIndex = 0;
	editEventManualIndex = 0;

	windowOutput = null;

	chart = Chart.parse(songName, 'normal');

	if (fileEvents != null)
	{
		for (ev in fileEvents)
		{
			if (!Reflect.hasField(ev, 'row'))
				ev.row = ev.type;
			if (!Reflect.hasField(ev, 'pointTo'))
				ev.pointTo = false;
			addEvent(ev);
		}
		fileEvents = null;
	}

	gridScale = 1;
}

function addEvent(event)
{
	events.push(event);
	switch (event.type)
	{
		case EVENT_BONE:
			boneEvents.push(event);
		case EVENT_BLASTER:
			blasterEvents.push(event);
		case EVENT_EDIT_BONE:
			editBoneEvents.push(event);
		case EVENT_EDIT_BOX:
			editBoxEvents.push(event);
		case EVENT_EDIT_SOUL:
			editSoulEvents.push(event);
		case EVENT_PLATFORM:
			platformEvents.push(event);
		case EVENT_EDIT_PLATFORM:
			editPlatformEvents.push(event);
	}

	if (hasheableEvents.contains(event.type))
	{
		hashList.get(event.type).push(event.params[0].id);
		//	trace('Registered hash from $' + event.type + ': ' + event.params[0].id);
	}

	sortEvents();
}

var clipShader;
var clipShaderGeneral;

function postCreate()
{
	clipShaderGeneral = new CustomShader('clipRect');
	clipShader = new CustomShader('clipRectEditor');

	camBattle = new FlxCamera();
	camBattle.bgColor = 0;
	camBattle.y -= 45;
	FlxG.cameras.add(camBattle, false);
	camBattle.addShader(clipShaderGeneral);

	camBattleClipped = new FlxCamera();
	camBattleClipped.bgColor = 0;
	camBattleClipped.y -= 45;
	FlxG.cameras.add(camBattleClipped, false);
	camBattleClipped.addShader(clipShaderGeneral);
	camBattleClipped.addShader(clipShader);

	// editor stuff
	setupSong();
	setupUI();

	var camBG = new FlxSprite();
	camBG.makeGraphic(FlxG.width * 0.515, FlxG.height * 0.515, 0xFFFFFFFF);
	camBG.screenCenter();
	camBG.y -= 45;
	add(camBG);

	bg = new FlxSprite();
	bg.makeGraphic(camBattle.width, camBattle.height, 0xFF000000);
	bg.camera = camBattle;
	add(bg);

	setupUndertaleHud();

	// undertale stuff
	box = new FightBox();
	box.boxWidth = constBoxWidth;
	box.boxHeight = constBoxHeight;
	box.thickness = constBoxThickness;
	box.setPosition(constBoxX, constBoxY);
	box.update(0);
	box.camera = box._container.camera = camBattle;
	add(box);

	blasterGrp = new FlxGroup();
	blasterGrp.camera = camBattle;
	blasterGrp.active = false;
	add(blasterGrp);

	boneGrp = new FlxGroup();
	boneGrp.active = false;
	add(boneGrp);

	platformGrp = new FlxGroup();
	platformGrp.camera = camBattle;
	add(platformGrp);

	camBattle.zoom = camBattleClipped.zoom = 0.5;
}

function setupUndertaleHud()
{
	var barW = 275;
	var barH = 40;

	bar = new FlxSprite();
	bar.makeGraphic(barW, barH, 0xFFFFFF00);
	bar.screenCenter(FlxAxes.X);
	bar.camera = camBattle;
	bar.y = FlxG.height * 0.885;
	add(bar);

	hpT = new FlxText();
	hpT.setFormat(Paths.font("undertale-hud.ttf"), 22, 0xFFFFFFFF);
	hpT.text = "hp";
	hpT.camera = camBattle;
	add(hpT);

	krT = new FlxText();
	krT.setFormat(Paths.font("undertale-hud.ttf"), 22, 0xFFFFFFFF);
	krT.text = "kr";
	krT.camera = camBattle;
	add(krT);

	hpT.scale.set(1, 0.8);
	krT.scale.set(1, 0.8);

	nameT = new FlxText();
	nameT.setFormat(Paths.font("undertale-hud.ttf"), 24, 0xFFFFFFFF);
	nameT.text = Sys.environment().get("USERNAME");
	nameT.camera = camBattle;
	add(nameT);

	levelT = new FlxText();
	levelT.setFormat(Paths.font("undertale-hud.ttf"), 24, 0xFFFFFFFF);
	levelT.text = "lv 69";
	levelT.camera = camBattle;
	add(levelT);

	var hudScale = 1.2;

	hud = new FlxSprite();
	hud.loadGraphic(Paths.image('ut/hud'));
	hud.scale.set(hudScale, hudScale);
	hud.updateHitbox();
	hud.screenCenter(FlxAxes.X);
	hud.y = FlxG.height * 0.92 - hud.height / 2;
	hud.camera = camBattle;
	add(hud);

	bar.origin.set(0, bar.height / 2);

	var baseY = FlxG.height * 0.8229;

	bar.y = baseY;

	hpT.x = bar.x - hpT.width - 5;
	hpT.y = bar.y + bar.height * 0.5 - hpT.height * 0.5;

	krT.x = bar.x + bar.width + 8;
	krT.y = bar.y + bar.height * 0.5 - krT.height * 0.5;

	nameT.x = FlxG.width * 0.12;
	nameT.y = bar.y + bar.height * 0.5 - nameT.height * 0.5;

	levelT.x = nameT.x + nameT.width + FlxG.width * 0.03;
	levelT.y = bar.y + bar.height * 0.5 - levelT.height * 0.5;
}

var hasheableEvents = [EVENT_BONE, EVENT_PLATFORM];
var editableEvents = [EVENT_EDIT_BONE, EVENT_EDIT_PLATFORM];

function editEvent(newData, eventIndex, specificIndex)
{
	events[eventIndex] = newData;
	switch (newData.type)
	{
		case EVENT_BLASTER:
			blasterEvents[specificIndex] = newData;
		case EVENT_BONE:
			boneEvents[specificIndex] = newData;
		case EVENT_EDIT_BONE:
			editBoneEvents[specificIndex] = newData;
		case EVENT_EDIT_BOX:
			editBoxEvents[specificIndex] = newData;
		case EVENT_EDIT_SOUL:
			editSoulEvents[specificIndex] = newData;
		case EVENT_PLATFORM:
			platformEvents[specificIndex] = newData;
		case EVENT_EDIT_PLATFORM:
			editPlatformEvents[specificIndex] = newData;
	}

	if (hasheableEvents.indexOf(newData.type) != -1)
	{
		trace("Trying to change IDs");
		for (id => ins in hashPendingEdit)
		{
			trace('ID Changed from $' + id + ' to $' + newData.params[0].id);
			hashList.get(ins.type)[ins.index] = newData.params[0].id;
		}
	}
}

function requestHashChange(type, id)
{
	trace('Requested hash change: [ ' + type + ', ' + id + ' ]');

	var list = hashList.get(type);
	if (list != null)
	{
		var index = list.indexOf(id);
		if (index >= 0)
		{
			hashPendingEdit.set(id, {
				type: type,
				index: index
			});
		}
	}
}

var cancelShit = false;

function update(elapsed)
{
	mouseInGrid = FlxG.mouse.x < GRID_SIZE * GRID_COUNT;
	if (controls.BACK)
	{
		_exit();
	}
	if (nextWindow != '')
	{
		var win = new UISubstateWindow(true, nextWindow);
		openSubState(win);

		nextWindow = '';

		cancelShit = true;
		return;
	}

	if (curContextMenu != null)
		cancelShit = true;
	editorSend = null;
	if (windowOutput != null)
	{
		if (editingEvent)
		{
			var oldEvent = events[editEventIndex];
			var newEvent = windowOutput;

			// @formatter:off
			editEvent(
				newEvent,
				editEventIndex,
				editEventManualIndex
			);
			// @formatter:on
			addToUndo({
				type: CSingleEdit,
				data: {
					oldEv: oldEvent,
					newEv: newEvent,
					eIndex: editEventIndex,
					eMIndex: editEventManualIndex
				}
			});

			editEventIndex = -1;
			editEventManualIndex = -1;
			editingEvent = false;
		}
		else
		{
			addEvent(windowOutput);

			addToUndo({
				type: CSingleAdd,
				data: windowOutput
			});
		}
		windowOutput = null;
	}

	if (presetOutput != null)
	{
		var shit = Reflect.copy(presetOutput);

		createPresetButton(shit);

		presetOutput = null;
		presetInput = null;
	}
	if (FlxG.keys.justPressed.R)
	{
		var s = new UIState();
		s.scriptName = "ut/AttackEditor";
		FlxG.switchState(s);
	}
	if (FlxG.mouse.released)
	{
		if (updatingTime)
		{
			if (!musicPaused)
				music.play();
			updatingTime = false;
		}
	}

	if (FlxG.mouse.justPressed)
	{
		if (uiSongSlider.members[uiSongSlider.members.length - 2].hovered)
		{
			updatingTime = true;
		}
	}

	if (!updatingTime)
	{
		uiSongSlider.value = music.time / music.length;
	}

	if (FlxG.keys.justPressed.SPACE)
	{
		if (musicPaused)
			music.resume();
		else
			music.pause();

		musicPaused = !musicPaused;
	}

	if (!FlxG.keys.pressed.CONTROL && FlxG.mouse.wheel != 0)
	{
		if (!musicPaused)
			music.pause();
		music.time += -FlxG.mouse.wheel * Conductor.crochet * Conductor.beatsPerMeasure * .5;
		if (!musicPaused)
			music.play();
	}
	Conductor.songPosition = music.time;

	if (FlxG.keys.pressed.CONTROL)
	{
		if (FlxG.keys.justPressed.V)
			_ui_paste();
		if (FlxG.keys.justPressed.C)
			_ui_copy();
	}

	// update bones clip rect
	final mp = box._container.getMidpoint();
	final midScreen = FlxPoint.get(FlxG.width / 2, FlxG.height / 2);

	// i hate hscript -theo
	mp.x -= midScreen.x;
	mp.y -= midScreen.y;
	mp.x *= camBattleClipped.zoom;
	mp.y *= camBattleClipped.zoom;
	mp.x += midScreen.x;
	mp.y += midScreen.y;

	final w = box.boxWidth * camBattleClipped.zoom;
	final h = box.boxHeight * camBattleClipped.zoom;
	clipShader.minX = FlxMath.remapToRange(mp.x - w / 2, 0, FlxG.width, 0, 1);
	clipShader.minY = FlxMath.remapToRange(mp.y - h / 2, 0, FlxG.height, 0, 1);
	clipShader.maxX = FlxMath.remapToRange(mp.x + w / 2, 0, FlxG.width, 0, 1);
	clipShader.maxY = FlxMath.remapToRange(mp.y + h / 2, 0, FlxG.height, 0, 1);
	mp.put();
	midScreen.put();

	// update general clip rect
	mp = bg.getMidpoint();
	midScreen = FlxPoint.get(FlxG.width / 2, FlxG.height / 2);

	// i hate hscript -theo
	mp.x -= midScreen.x;
	mp.y -= midScreen.y;
	mp.x *= camBattle.zoom;
	mp.y *= camBattle.zoom;
	mp.x += midScreen.x;
	mp.y += midScreen.y;

	final w = camBattle.width * camBattle.zoom;
	final h = camBattle.height * camBattle.zoom;
	clipShaderGeneral.minX = FlxMath.remapToRange(mp.x - w / 2, 0, FlxG.width, 0, 1);
	clipShaderGeneral.minY = FlxMath.remapToRange(mp.y - h / 2, 0, FlxG.height, 0, 1);
	clipShaderGeneral.maxX = FlxMath.remapToRange(mp.x + w / 2, 0, FlxG.width, 0, 1);
	clipShaderGeneral.maxY = FlxMath.remapToRange(mp.y + h / 2, 0, FlxG.height, 0, 1);
	mp.put();
	midScreen.put();

	if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
		runUndo();
	if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
		runRedo();
}

function createPresetButton(data)
{
	var presetButton = new PresetButton(uiPresetBox.bWidth - (35 * 3), 30, data, () -> _ui_insert_preset(data));
	presetButton.field.fieldWidth = presetButton.bWidth;
	presetButton.field.alignment = 'center';
	uiPresetBox.add(presetButton);

	presetButton.onDelete = _ui_remove_preset;
	presetButton.onSave = _ui_save_preset;
}

function postUpdate(elapsed)
{
	if (!cancelShit)
	{
		updateUI(elapsed);
		updateGrids(elapsed);
		updateSelection(elapsed);
		updateEvents(elapsed);
	}
	cancelShit = false;
}

var curQuant = 4;

function getTimeQuantizated(rawTime:Float):Float
{
	if (FlxG.keys.pressed.SHIFT)
		return rawTime * Conductor.crochet; // sin cuantizar

	final quantizedBeats = Math.round(rawTime * curQuant) / curQuant;
	return quantizedBeats * Conductor.crochet; // cuantizado
}

function getTimeFromWorldY(worldY:Float):Float
{
	final rawTime = (worldY - uiGridPosition) / GRID_SIZE; // beats
	return getTimeQuantizated(rawTime / gridScale);
}

function updateUI(elapsed)
{
	uiSongSlider.startText.text = FlxStringUtil.formatTime(music.time * 0.001, false);
	uiSongSlider.endText.text = FlxStringUtil.formatTime(music.length * 0.001, false);
	uiSelectionBox.visible = false;

	if (FlxG.mouse.justReleasedRight)
	{
		closeCurrentContextMenu();
		openContextMenu(uiContextPopups[getContextAction()].childs, null, FlxG.mouse.x, FlxG.mouse.y);
	}

	uiInfoText.text = 'Music Time: '
		+ limitDecimal(Conductor.songPosition * 0.001)
		+ 's'
		+ '\n\nCursor Time: '
		+ limitDecimal((getTimeFromWorldY(uiGridGrabber.y)) * 0.001)
		+ 's'
		+ '\n\nSoul Mode: '
		+ curSoulMode
		+ '\n\nSoul Angle: '
		+ curSoulGroundAngle
		+ '\n\nMarquee State: '
		+ slBoxState;
}

function updateEvents(elapsed:Float)
{
	var position = Conductor.songPosition;

	var blasterCount = 0;
	var boneCount = 0;
	var platformCount = 0;

	for (blaster in blasters)
	{
		blaster.timePosition = -1;
	}
	for (bone in bones)
	{
		bone.visible = false;
	}
	for (plat in platforms)
	{
		plat.visible = false;
	}
	for (event in events)
	{
		if (event.type == EVENT_EDIT_PLATFORM
			|| event.type == EVENT_EDIT_BONE
			|| event.type == EVENT_EDIT_BOX
			|| position < event.time)
			continue;
		// blaster
		if (event.type == EVENT_BLASTER)
		{
			final eventElapsed = (position - event.time) * 0.001;

			if (Blaster.isUseless(event.params[0], eventElapsed))
				continue;

			var blaster:Blaster;

			if (blasterCount < blasters.length)
			{
				blaster = blasters[blasterCount];
			}
			else
			{
				blaster = new Blaster();
				blaster.dirtyTimeline = true;
				blaster.quiet = true;
				// prevents from updating by itself, fixes visual issues
				blasterGrp.add(blaster);

				blasters.push(blaster);
			}
			var paramsCopy = Reflect.copy(event.params[0]);
			paramsCopy.initialPosition = FlxPoint.get(paramsCopy.initialPositionX, paramsCopy.initialPositionY);
			paramsCopy.attackPosition = FlxPoint.get(paramsCopy.attackPositionX, paramsCopy.attackPositionY);

			if (paramsCopy.pointTo)
			{
				paramsCopy.attackAngle = FlxAngle.degreesFromOrigin(FlxG.width * .5 - paramsCopy.attackPosition.x,
					FlxG.height * .5 - paramsCopy.attackPosition.y);
			}

			blaster.setup(paramsCopy);
			blaster.start();
			blaster.timePosition = eventElapsed;
			blasterCount++;
		}
		// bone
		else if (event.type == EVENT_BONE)
		{
			var editEvs = [];

			for (edEv in editBoneEvents)
			{
				if (edEv == null)
					continue;
				if ((position >= edEv.time) && (edEv.params[0].id == event.params[0].id))
				{
					editEvs.push(edEv);
				}
			}

			editEvs.sort(function(a, b) return Reflect.compare(a.time, b.time));

			var bone:Bone;
			var data = event.params[0];
			if (boneCount < bones.length)
			{
				bone = bones[boneCount];
			}
			else
			{
				bone = new Bone(0, 0, 50, 10);
				bone.moves = false;
				bone.center = true;
				boneGrp.add(bone);
				bones.push(bone);
			}

			bone.indentifier = data.id;
			bone.setPosition(data.positionX, data.positionY);
			bone.boneWidth = data.width;
			bone.boneHeight = data.height;
			bone.visible = true;
			bone.type = data?.mode ?? "normal";

			bone.angle = data.angle;

			bone.velocity.x = data.vX;
			bone.velocity.y = data.vY;
			bone.angularVelocity = data.vA;

			bone.camera = data.out ? camBattle : camBattleClipped;

			var boneBaseX = data.positionX;
			var boneBaseY = data.positionY;
			var boneBaseA = data.angle;

			var velKeyframesX = [];
			var velKeyframesY = [];
			var velKeyframesA = [];

			var bonePos = position;
			final eventElapsUnclipped = (bonePos - event.time) * 0.001;

			if (editEvs.length != 0)
				bonePos = Math.min(position, editEvs[0].time);

			final eventElapsed = (bonePos - event.time) * 0.001;

			if (editEvs.length != 0)
			{
				for (i in 0...editEvs.length)
				{
					final editEv = editEvs[i];
					final nextEditEv = editEvs[i + 1];
					final lastData = i == 0 ? data : (editEvs[i - 1]);
					final ease = CoolUtil.flxeaseFromString(editEv.params[0].tweenName, '') ?? FlxEase.linear;
					final tweenDur = Math.max(0.0001, editEv.params[0].tweenDur);

					var editPos = position;
					if (nextEditEv != null)
						editPos = Math.min(position, nextEditEv.time);
					final editElapsed = (editPos - editEv.time) * 0.001;
					final dataEdit = editEv.params[0];
					final ratio = ease(Math.min(editElapsed, tweenDur) / tweenDur);

					if (dataEdit.positionX != -1)
						boneBaseX = FlxMath.lerp(lastData.positionX, dataEdit.positionX, ratio);
					if (dataEdit.positionY != -1)
						boneBaseY = FlxMath.lerp(lastData.positionY, dataEdit.positionY, ratio);
					if (dataEdit.angle != -1)
						boneBaseA = FlxMath.lerp(lastData.angle, dataEdit.angle, ratio);

					if (dataEdit.width != -1)
						bone.boneWidth = FlxMath.lerp(lastData.width, dataEdit.width, ratio);
					if (dataEdit.height != -1)
						bone.boneHeight = FlxMath.lerp(lastData.height, dataEdit.height, ratio);

					if (dataEdit.vX != -1)
						velKeyframesX.push({
							startTime: (editEv.time - event.time) * 0.001,
							tweenDur: tweenDur,
							easeFunc: ease,
							newVel: dataEdit.vX
						});

					if (dataEdit.vY != -1)
						velKeyframesY.push({
							startTime: (editEv.time - event.time) * 0.001,
							tweenDur: tweenDur,
							easeFunc: ease,
							newVel: dataEdit.vY
						});

					if (dataEdit.vA != -1)
						velKeyframesA.push({
							startTime: (editEv.time - event.time) * 0.001,
							tweenDur: tweenDur,
							easeFunc: ease,
							newVel: dataEdit.vA
						});

					if (dataEdit.mode != "*last*" || dataEdit.mode != "")
						bone.type = dataEdit?.mode ?? "normal";
				}
			}

			bone.x = boneBaseX + keyframeAlgorithm(0, data.vX, eventElapsUnclipped, velKeyframesX);
			bone.y = boneBaseY + keyframeAlgorithm(0, data.vY, eventElapsUnclipped, velKeyframesY);
			bone.angle = boneBaseA + keyframeAlgorithm(0, data.vA, eventElapsUnclipped, velKeyframesA);

			boneCount++;
		}
		else if (event.type == EVENT_PLATFORM)
		{
			var editEvs = [];

			for (edEv in editPlatformEvents)
			{
				if (edEv == null)
					continue;
				if ((position >= edEv.time) && (edEv.params[0].id == event.params[0].id))
				{
					editEvs.push(edEv);
				}
			}

			editEvs.sort(function(a, b) return Reflect.compare(a.time, b.time));

			var data = event.params[0];

			var platform:Platform;
			if (platformCount < platforms.length)
			{
				platform = platforms[platformCount];
			}
			else
			{
				platform = new Platform(0, 0, 10, 10);
				platform.thickness = 6;
				platform.moves = false;
				platformGrp.add(platform);

				platforms.push(platform);
			}

			platform.setPosition(data.positionX, data.positionY);
			platform.velocity.x = data.vX;
			platform.velocity.y = data.vY;
			platform.boxWidth = data.width;
			platform.boxHeight = data.height;
			platform.visible = true;

			var platformBaseX = data.positionX;
			var platformBaseY = data.positionY;

			var velKeyframesX = [];
			var velKeyframesY = [];
			var velKeyframesA = [];

			var platformPos = position;
			final eventElapsUnclipped = (platformPos - event.time) * 0.001;
			if (editEvs.length != 0)
				platformPos = Math.min(position, editEvs[0].time);

			final eventElapsed = (platformPos - event.time) * 0.001;

			if (editEvs.length != 0)
			{
				for (i in 0...editEvs.length)
				{
					final editEv = editEvs[i];
					final nextEditEv = editEvs[i + 1];

					final lastData = i == 0 ? data : (editEvs[i - 1]);
					final ease = CoolUtil.flxeaseFromString(editEv.params[0].tweenName, '') ?? FlxEase.linear;
					final tweenDur = Math.max(0.0001, editEv.params[0].tweenDur);

					var editPos = position;

					if (nextEditEv != null)
						editPos = Math.min(position, nextEditEv.time);

					final editElapsed = (editPos - editEv.time) * 0.001;

					var dataEdit = editEv.params[0];
					final ratio = ease(Math.min(editElapsed, tweenDur) / tweenDur);

					if (dataEdit.positionX != -1)
						platformBaseX = FlxMath.lerp(lastData.positionX, dataEdit.positionX, ratio);
					if (dataEdit.positionY != -1)
						platformBaseY = FlxMath.lerp(lastData.positionY, dataEdit.positionY, ratio);

					if (dataEdit.width != -1)
						platform.boxWidth = FlxMath.lerp(lastData.width, dataEdit.width, ratio);
					if (dataEdit.height != -1)
						platform.boxHeight = FlxMath.lerp(lastData.height, dataEdit.height, ratio);

					if (dataEdit.vX != -1)
						velKeyframesX.push({
							startTime: (editEv.time - event.time) * 0.001,
							tweenDur: tweenDur,
							easeFunc: ease,
							newVel: dataEdit.vX
						});

					if (dataEdit.vY != -1)
						velKeyframesY.push({
							startTime: (editEv.time - event.time) * 0.001,
							tweenDur: tweenDur,
							easeFunc: ease,
							newVel: dataEdit.vY
						});
				}
			}
			platform.x = platformBaseX + keyframeAlgorithm(0, data.vX, eventElapsUnclipped, velKeyframesX);
			platform.y = platformBaseY + keyframeAlgorithm(0, data.vY, eventElapsUnclipped, velKeyframesY);

			platformCount++;
		}
	}

	box.boxWidth = constBoxWidth;
	box.boxHeight = constBoxHeight;
	box.thickness = constBoxThickness;
	box.angle = 0;
	box.setPosition(constBoxX, constBoxY);

	var boxEdits = editBoxEvents.copy();
	boxEdits.sort(function(a, b) return Reflect.compare(a.time, b.time));

	if (boxEdits.length != 0)
	{
		for (i in 0...boxEdits.length)
		{
			final editEv = boxEdits[i];

			if (position < editEv.time)
				continue;

			final nextEditEv = boxEdits[i + 1];

			final ease = CoolUtil.flxeaseFromString(editEv.params[0].tweenName, '') ?? FlxEase.linear;
			final tweenDur = Math.max(0.0001, editEv.params[0].tweenDur);

			var editPos = position;

			if (nextEditEv != null)
				editPos = Math.min(position, nextEditEv.time);

			final editElapsed = (editPos - editEv.time) * 0.001;
			var dataEdit = editEv.params[0];

			final ratio = ease(Math.min(editElapsed, tweenDur) / tweenDur);

			var lastWidth = box.boxWidth;
			var lastHeight = box.boxHeight;

			if (dataEdit.width != -1)
				box.boxWidth = FlxMath.lerp(box.boxWidth, dataEdit.width, ratio);
			if (dataEdit.height != -1)
				box.boxHeight = FlxMath.lerp(box.boxHeight, dataEdit.height, ratio);

			box.x = FlxMath.lerp(box.x, minusShit(dataEdit.positionX, box.x) + (lastWidth - minusShit(dataEdit.width, lastWidth)) * .5, ratio);
			box.y = FlxMath.lerp(box.y, minusShit(dataEdit.positionY, box.y) + (lastHeight - minusShit(dataEdit.height, lastHeight)) * .5, ratio);
			if (dataEdit.angle != -1)
				box.angle = FlxMath.lerp(box.angle, dataEdit.angle, ratio);
		}
	}

	curSoulMode = 'normal';
	curSoulGroundAngle = 0;

	if (editSoulEvents.length != 0)
	{
		for (event in editSoulEvents)
		{
			if (position < event.time)
				continue;

			var params = event.params[0];

			curSoulMode = params.mode;
			curSoulGroundAngle = params.groundAngle;
		}
	}

	blasterGrp.update(elapsed);
	boneGrp.update(elapsed);
}

function minusShit(val, rep)
{
	return val == -1 ? rep : val;
}

function aabbCollision(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float):Bool
{
	return (x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2);
}

var insideGrid = false;
var curRow = 0;

// TODO: Add to undo
function snapEvents(list)
{
	for (event in list)
	{
		final before = event.data.time;
		event.data.time = getTimeQuantizated(event.data.time / Conductor.crochet);
		trace(before, event.data.time);
	}
}

function updateGrids(elapsed:Float)
{
	var scaled = false;
	if (FlxG.keys.pressed.CONTROL && FlxG.mouse.wheel != 0)
	{
		gridScale += FlxG.mouse.wheel * 0.25;
		scaled = true;
	}

	gridScale = Math.max(0.1, gridScale);

	var lastQuant = curQuant;
	curQuant = 4;
	uiGridPosition = GRID_SIZE * 8 + ((-getTimeQuantizated(curBeatFloat) / Conductor.crochet) * GRID_SIZE) * gridScale;
	curQuant = lastQuant;

	for (i in 0...uiGrids.length)
	{
		uiGrids[i].x = GRID_SIZE * i;
		uiGrids[i].y = FlxMath.lerp(uiGrids[i].y, uiGridPosition, scaled ? 1 : 0.5 * 60 * elapsed);
	}
	uiEventBackdrop.y = FlxMath.lerp(uiEventBackdrop.y, uiGridPosition, scaled ? 1 : 0.5 * 60 * elapsed);

	var eventCount = 0;
	insideGrid = false;

	for (grid in uiGrids)
	{
		grid.scale.y = (gridScale * GRID_SIZE) / GRID_SIZE;
		grid.updateHitbox();
	}
	uiEventBackdrop.setGraphicSize(uiEventBackdrop.width, GRID_SIZE * 2 * gridScale);
	uiEventBackdrop.updateHitbox();

	for (i in 0...uiGrids.length)
	{
		if (FlxG.mouse.x > uiGrids[i].x && FlxG.mouse.x < uiGrids[i].x + uiGrids[i].width)
		{
			uiCurrentGridRow = i;
			uiGridGrabber.y = (uiGridPosition + ((getTimeFromWorldY(FlxG.mouse.y) * gridScale) / Conductor.crochet) * GRID_SIZE) - uiGridGrabber.height * .5;
			insideGrid = true;
			break;
		}
	}
	if (!uiEventSelecting)
		uiGridGrabber.x = uiGrids[uiCurrentGridRow].x + GRID_SIZE * .25;

	for (event in eventSprites)
		event.visible = false;

	for (i => event in events)
	{
		var eventSprite:EventUI;

		if (eventCount < eventSprites.length)
		{
			eventSprite = eventSprites[eventCount++];
		}
		else
		{
			eventSprite = new EventUI(0, 0);
			eventSprite.ID = eventSprites.length;
			uiEventGrp.add(eventSprite);
			eventSprites.push(eventSprite);
		}

		var graphic;

		switch (event.type)
		{
			case EVENT_BLASTER:
				graphic = BLASTER_ICON_GRAPHIC;
			case EVENT_BONE:
				graphic = BONE_ICON_GRAPHIC;
			case EVENT_EDIT_BONE:
				graphic = EDIT_BONE_ICON_GRAPHIC;
			case EVENT_EDIT_BOX:
				graphic = EDIT_BOX_ICON_GRAPHIC;
			case EVENT_EDIT_SOUL:
				graphic = EDIT_SOUL_ICON_GRAPHIC;
			case EVENT_PLATFORM:
				graphic = PLATFORM_ICON_GRAPHIC;
			case EVENT_EDIT_PLATFORM:
				graphic = EDIT_PLATFORM_ICON_GRAPHIC;
		}
		eventSprite.loadGraphic(Paths.image('ut/editor/' + graphic));
		eventSprite.setGraphicSize(GRID_SIZE, GRID_SIZE);
		eventSprite.updateHitbox();
		eventSprite.scale.set(eventSprite.scale.x * eventSprite.scaleLerped, eventSprite.scale.y * eventSprite.scaleLerped);
		eventSprite.data = event;
		eventSprite.visible = true;

		var indexShit = -1;

		if (queueSelect.length != 0)
			indexShit = queueSelect.indexOf(event);

		if (indexShit != -1)
		{
			slBoxState = B_SELECTED;

			queueSelect.splice(indexShit, 1);
			addToSelection(eventSprite);
		}

		// determine row index by type
		var rowIndex = event.row;

		// get corresponding grid
		var grid = uiGrids[rowIndex];

		if (grid == null)
			trace(rowIndex);

		var beat = (Conductor.getStepForTime(event.time) / Conductor.stepsPerBeat);

		var posY = (grid.y + (beat) * GRID_SIZE * gridScale) + GRID_SIZE * .5 * gridScale - eventSprite.height * .5;
		eventSprite.y = posY;
		// keep aligned horizontally with grid
		eventSprite.x = grid.x;
	}
}

function _ui_edit_event(event)
{
	music.pause();
	musicPaused = true;

	editorSend = event.data;
	editingEvent = true;
	var win;

	switch (event.data.type)
	{
		case EVENT_BLASTER:
			win = 'ut/editor/events/BlasterCreationScreen';
		case EVENT_BONE:
			win = 'ut/editor/events/BoneCreationScreen';
		case EVENT_EDIT_BONE:
			win = 'ut/editor/events/EditBoneMotionScreen';
		case EVENT_EDIT_BOX:
			win = 'ut/editor/events/BoxEditScreen';
		case EVENT_EDIT_SOUL:
			win = 'ut/editor/events/EditSoulScreen';
		case EVENT_PLATFORM:
			win = 'ut/editor/events/PlatformCreationScreen';
		case EVENT_EDIT_PLATFORM:
			win = 'ut/editor/events/EditPlatformScreen';
	}

	if (hasheableEvents.contains(event.data.type))
	{
		requestHashChange(event.data.type, event.data.params[0].id);
	}

	editEventIndex = events.indexOf(event.data);
	switch (event.data.type)
	{
		case EVENT_BLASTER:
			editEventManualIndex = blasterEvents.indexOf(event.data);
		case EVENT_BONE:
			editEventManualIndex = boneEvents.indexOf(event.data);
		case EVENT_EDIT_BONE:
			editEventManualIndex = editBoneEvents.indexOf(event.data);
		case EVENT_EDIT_BOX:
			editEventManualIndex = editBoxEvents.indexOf(event.data);
		case EVENT_EDIT_SOUL:
			editEventManualIndex = editSoulEvents.indexOf(event.data);
		case EVENT_PLATFORM:
			editEventManualIndex = platformEvents.indexOf(event.data);
		case EVENT_EDIT_PLATFORM:
			editEventManualIndex = editPlatformEvents.indexOf(event.data);
	}

	nextWindow = win;
}

/**
 * Box Behavior
 * 0x00 INACTIVE
 * 0x01 SELECTING
 * 0x02 DID SELECT / HAS SELECTION
 * 0x03 DRAGGING / MOVING ITEMS
 */
final B_NONE = 0x00;

final B_SELECTING = 0x01;
final B_SELECTED = 0x02;
final B_DRAGGING = 0x03;

// selection SHITTT
var slItems = [];
var slBoxState = B_NONE;
var slLastBoxState = slBoxState;
var slBoxQueue = false;
var slAuxPoint = FlxPoint.get();
var slClicks = 0;
var slClickTmr = 0;

// copying & pasting
var copyList = [];
var isCopying = false;

// others
var mouseInGrid = false;
var _temporalDragInfo;

function updateSelection(elapsed)
{
	var control = (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.SHIFT);
	var pressedBox = FlxG.mouse.justPressed && control;
	var releasedBox = FlxG.mouse.justReleased || !control;

	// single event selection logic
	if ((slBoxState == B_NONE || slItems.length == 1) && FlxG.mouse.justPressed && !control)
	{
		var eventSelected = null;
		for (item in eventSprites)
		{
			if (FlxG.mouse.overlaps(item))
			{
				clearSelection();

				slBoxState = B_SELECTED;
				addToSelection(item);
				break;
			}
		}
	}

	// dragging logic
	var justHovered = false;
	if (slBoxState == B_SELECTED && FlxG.mouse.justPressed)
	{
		for (item in slItems)
		{
			if (FlxG.mouse.overlaps(item))
			{
				slBoxState = B_DRAGGING;
				justHovered = true;

				_temporalDragInfo = [];
				_temporalDragInfo.resize(slItems.length);

				for (i => item2 in slItems)
				{
					_temporalDragInfo[i] = {
						event: item2.data,
						oldPos: item2.data.time,
						oldRow: item2.data.row,
						newPos: 0,
						newRow: 0
					};
				}

				break;
			}
		}
	}
	if (slBoxState == B_DRAGGING)
	{
		var end = false;
		if (FlxG.mouse.justReleased)
		{
			slBoxState = B_SELECTED;

			end = true;
			// fix
			releasedBox = false;
		}

		for (i => item in slItems)
		{
			if (justHovered)
			{
				item.rowPoint = item.data.row - uiCurrentGridRow;
				item.dragPoint = item.data.time - getTimeFromWorldY(uiGridGrabber.y);
			}
			else
			{
				item.data.time = item.dragPoint + getTimeFromWorldY(uiGridGrabber.y);
				item.data.row = Math.min(GRID_COUNT - 1, Math.max(0, item.rowPoint + uiCurrentGridRow));
			}

			if (end)
			{
				_temporalDragInfo[i].newPos = item.data.time;
				_temporalDragInfo[i].newRow = item.data.row;
			}
		}

		if (end)
		{
			if ((_temporalDragInfo[0].oldRow != _temporalDragInfo[0].newRow)
				|| Math.abs(_temporalDragInfo[0].oldPos - _temporalDragInfo[0].newPos) >= 1)
			{
				addToUndo({
					type: CStackDrag,
					data: _temporalDragInfo
				});

				_temporalDragInfo = null;
			}
		}
	}

	// deselection logic (very easy)
	if (slClicks > 0)
	{
		slClickTmr += elapsed;

		if (slClickTmr >= 0.35)
		{
			slClicks--;
			slClickTmr = 0;
		}

		if (slClicks >= 2)
		{
			slClicks = 0;
			clearSelection();
			trace('cleared');
		}
	}
	if (slBoxState == B_SELECTED && FlxG.mouse.justPressed && !control)
	{
		slClicks++;
	}

	// selection logic
	uiSelectionBox.visible = false;

	// while selecting
	if (slBoxState == B_SELECTING)
	{
		if (releasedBox)
		{
			slBoxState = slItems.length != 0 ? B_SELECTED : B_NONE;
			uiSelectionBox.scale.set(1, 1);

			for (item in eventSprites)
			{
				item.dragOnce = false;
			}

			return;
		}

		uiSelectionBox.visible = true;
		var curPoint = FlxG.mouse.getPosition();

		var x = Math.min(curPoint.x, slAuxPoint.x);
		var y = Math.min(curPoint.y, slAuxPoint.y);
		var width = Math.max(1, Math.abs(curPoint.x - slAuxPoint.x));
		var height = Math.max(1, Math.abs(curPoint.y - slAuxPoint.y));

		uiSelectionBox.x = x;
		uiSelectionBox.y = y;
		uiSelectionBox.bWidth = width;
		uiSelectionBox.bHeight = height;

		// i wanna to keep the code clean so i moved here to a separate function
		handleBoxSelection(slAuxPoint, curPoint);

		curPoint.put();
	}

	if (releasedBox && slBoxQueue)
	{
		slBoxQueue = false;
	}

	if (pressedBox && mouseInGrid)
	{
		slBoxQueue = true;
		slAuxPoint.set(FlxG.mouse.x, FlxG.mouse.y);
	}

	if (slBoxQueue)
	{
		var dx = FlxG.mouse.x - slAuxPoint.x;
		var dy = FlxG.mouse.y - slAuxPoint.y;

		if (FlxMath.vectorLength(dx, dy) > 5)
		{
			slBoxState = B_SELECTING;
			slBoxQueue = false;
		}
	}

	for (item in eventSprites)
	{
		item.color = getColorFromEvent(item);
		item.scaleOff = item.selected ? (slBoxState == B_DRAGGING ? 1.35 : 1.085) : 1;
	}

	uiGridGrabber.visible = (slBoxState == B_NONE || slBoxState == B_SELECTED) && insideGrid;
	slLastBoxState = slBoxState;
}

function getColorFromEvent(spr)
{
	final data = spr.data;

	var color = new FlxInterpolateColor(0xFFFFFFFF);
	if (data.type == EVENT_BONE)
	{
		color = new FlxInterpolateColor(Bone.DEFAULT_COLORS.get(data.params[0].mode));
	}

	if (spr.selected)
		color.lerpTo(0xFF9C7BE9, 0.5);
	return color.color;
}

function clearSelection()
{
	for (item in slItems)
		item.selected = false;
	slItems = [];
	slBoxState = B_NONE;
}

function addToSelection(item)
{
	item.selected = true;
	slItems.push(item);
}

function handleBoxSelection(p1, p2)
{
	var x1 = Math.min(p1.x, p2.x);
	var y1 = Math.min(p1.y, p2.y);
	var x2 = Math.max(p1.x, p2.x);
	var y2 = Math.max(p1.y, p2.y);

	var newSelection = [];

	for (obj in eventSprites)
	{
		if (aabbCollision(x1, y1, x2 - x1, y2 - y1, obj.x, obj.y, obj.width, obj.height))
		{
			newSelection.push(obj);
		}
	}

	if (FlxG.keys.pressed.SHIFT)
	{
		for (o in newSelection)
		{
			var hovered = slItems.contains(o);

			if (o.dragOnce)
				continue;

			if (hovered)
				slItems.remove(o);
			else
				slItems.push(o);

			o.selected = !hovered;
			o.dragOnce = true;
		}
	}
	else
	{
		for (o in slItems)
		{
			o.selected = false;
		}

		slItems = newSelection;

		for (o in slItems)
		{
			o.selected = true;
		}
	}
}

function setupGrids()
{
	for (i in 0...GRID_COUNT)
	{
		var colors = [0xFF272727, 0xFF545454];

		if (i % 2 == 0)
			colors.reverse();
		var gridBmp = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 2, true, colors[0], colors[1]);
		var grid = new FlxBackdrop(gridBmp.graphic, 0x10);
		grid.y = 40 + i * GRID_SIZE * 2;
		uiGrids.push(grid);
		uiGroup.add(grid);
	}
}

function setupSong()
{
	music = FlxG.sound.load(Paths.inst(songName, ''));
	music.onComplete = () ->
	{
		music.pause();
		music.play();
	};

	var beatsPerMeasure:Float = chart.meta.beatsPerMeasure;
	var stepsPerBeat:Int = chart.meta.stepsPerBeat;

	Conductor.mapBPMChanges(chart);
	Conductor.changeBPM(chart.meta.bpm, beatsPerMeasure, stepsPerBeat);

	music.play();
	music.pause();
	musicPaused = true;

	music.time = startTime;
}

function setupUI()
{
	backdrop = new FlxBackdrop();
	backdrop.loadGraphic(Paths.image('ut/editor/bg'));
	backdrop.velocity.set(20, 20);
	add(backdrop);

	uiCam = new FlxCamera();
	uiCam.bgColor = 0;
	FlxG.cameras.add(uiCam, false);

	uiGroup = new FlxGroup();
	uiGroup.camera = uiCam;
	add(uiGroup);

	setupGrids();

	uiEventGrp = new FlxGroup();
	uiGroup.add(uiEventGrp);

	uiSelectionBox = new UISliceSprite(0, 0, 2, 2, 'editors/ui/selection');
	uiSelectionBox.visible = false;
	uiSelectionBox.incorporeal = true;
	uiGroup.add(uiSelectionBox);

	uiTimeLine = new FlxSprite(0, GRID_SIZE * 8);
	uiTimeLine.makeGraphic(GRID_SIZE * GRID_COUNT + 5, 2, 0xFFFFFFFF);
	uiTimeLine.camera = uiCam;
	add(uiTimeLine);

	uiEventStart = new FlxSprite();
	uiEventStart.makeGraphic(GRID_SIZE * GRID_COUNT, GRID_SIZE * 8, 0x75000000);
	uiGroup.add(uiEventStart);

	uiEventBackdrop = new FlxBackdrop(Paths.image('editors/charter/events-grid'), 0x10);
	uiEventBackdrop.flipX = true;
	uiEventBackdrop.x = GRID_SIZE * GRID_COUNT;
	uiEventBackdrop.y = 40 * GRID_SIZE * 2;
	uiEventBackdrop.setGraphicSize(uiEventBackdrop.width, GRID_SIZE * 2);
	uiEventBackdrop.updateHitbox();
	uiGroup.add(uiEventBackdrop);

	uiGridHeader = new UISprite();
	uiGridHeader.loadGraphic(Paths.image('editors/charter/strumline-info-bg'));
	uiGridHeader.setGraphicSize(GRID_SIZE * GRID_COUNT, GRID_SIZE * 4);
	uiGridHeader.updateHitbox();
	uiGroup.add(uiGridHeader);

	uiGridGrabber = new FlxSprite();
	uiGridGrabber.makeGraphic(GRID_SIZE * .5, GRID_SIZE * .5, 0x00FFFFFF);
	uiGridGrabber = FlxSpriteUtil.drawCircle(uiGridGrabber, -1, -1, -1, 0x6EFFFFFF);
	uiGroup.add(uiGridGrabber);

	uiInfoBG = new UISliceSprite(FlxG.width - 270 - 20, 185, 270, 500, "editors/ui/inputbox");
	uiInfoBG.alpha = 0.7;
	uiGroup.add(uiInfoBG);

	uiInfoText = new FlxText(uiInfoBG.x + 25, uiInfoBG.y + 25, uiInfoBG.bWidth - 25 * 2);
	uiInfoText.alignment = 'left';
	uiInfoText.size = 21;
	uiInfoText.font = Paths.font('vcr.ttf');
	uiGroup.add(uiInfoText);

	uiSliceBG = new UISliceSprite(20 + GRID_SIZE * GRID_COUNT, FlxG.height - 250, FlxG.width - GRID_SIZE * GRID_COUNT - 307 - 20, 235, "editors/ui/inputbox");
	uiSliceBG.alpha = 0.7;
	uiGroup.add(uiSliceBG);

	uiSongBox = new UISliceSprite(uiSliceBG.x + 20, uiSliceBG.y + 20, 300, uiSliceBG.bHeight - 40, "editors/ui/button");
	uiSongBox.alpha = 0.7;
	uiGroup.add(uiSongBox);

	uiPresetBox = new UIButtonList(uiSongBox.x + uiSongBox.bWidth + 20, uiSliceBG.y + 20, 370, uiSliceBG.bHeight - 40, '', FlxPoint.get(370 - 40, 30));
	uiPresetBox.frames = Paths.getFrames('editors/ui/button');
	uiPresetBox.alpha = 0.7;
	uiPresetBox.addButton.callback = _ui_import_preset;
	uiGroup.add(uiPresetBox);

	uiSongRewind = new UIButton(uiSongBox.x + uiSongBox.bWidth * .25 - 55 * .5, uiSongBox.y + 70, '<<', () ->
	{
		if (!musicPaused)
			music.pause();
		music.time -= Conductor.crochet * 2;
		if (!musicPaused)
			music.resume();
	}, 55, 50);
	uiSongRewind.color = 0xff868686;
	uiSongBox.members.push(uiSongRewind);

	uiSongForward = new UIButton(uiSongBox.x + uiSongBox.bWidth * (1 - .25) - 55 * .5, uiSongBox.y + 70, '>>', () ->
	{
		if (!musicPaused)
			music.pause();
		music.time += Conductor.crochet * 2;
		if (!musicPaused)
			music.resume();
	}, 55, 50);
	uiSongForward.color = 0xff868686;
	uiSongBox.members.push(uiSongForward);

	uiSongPause = new UIButton(uiSongBox.x + uiSongBox.bWidth * .5 - 80 * .5, uiSongBox.y + 60, '', () ->
	{
		if (musicPaused)
			music.resume();
		else
			music.pause();
		musicPaused = !musicPaused;
	}, 80, 70);
	uiSongPause.frames = Paths.getFrames("editors/ui/grayscale-button");
	uiSongPause.color = 0xFF743737;
	uiSongBox.members.push(uiSongPause);

	uiSongPauseIcon = new FlxSprite().loadGraphic(Paths.image('editors/ui/audio-buttons'), true, 16, 16);
	uiSongPauseIcon.animation.add("paused", [0]);
	uiSongPauseIcon.antialiasing = false;
	uiSongPauseIcon.scale.set(1.5, 1.5);
	uiSongPauseIcon.updateHitbox();
	uiSongPauseIcon.animation.play('playing');
	uiSongPauseIcon.setPosition(uiSongPause.x
		+ uiSongPause.bWidth * .5
		- uiSongPauseIcon.width * .5,
		uiSongPause.y
		+ uiSongPause.bHeight * .5
		- uiSongPauseIcon.height * .5);
	uiSongBox.members.push(uiSongPauseIcon);

	uiSongSlider = new UISlider(uiSongBox.x + uiSongBox.bWidth * .5 - (uiSongBox.bWidth * .55) * .5 - 4, uiSongBox.y + 165, uiSongBox.bWidth * .58, 0,
		[{start: 0, end: 1, size: 1}], false);
	uiSongSlider.onChange = function(v)
	{
		if (updatingTime)
		{
			trace('ay');
			if (!musicPaused)
				music.pause();
			music.time = (music.length * v);
			if (!musicPaused)
				music.play();
		}
	};
	uiSongSlider.valueStepper.visible = false;
	uiSongBox.members.push(uiSongSlider);

	uiAddButton = new UIButton(FlxG.width - 270 - 20, FlxG.height - 75 - 18, null, _ui_addEvent, 270, 75);
	uiAddButton.autoAlpha = false;
	uiAddButton.frames = Paths.getFrames("editors/ui/grayscale-button");
	uiGroup.add(uiAddButton);

	uiAddIcon = new FlxSprite(uiAddButton.x + 45, uiAddButton.y + 21).loadGraphic(Paths.image('ut/editor/add'));
	uiAddIcon.antialiasing = false;
	uiAddIcon.scale.scale(2);
	uiAddIcon.updateHitbox();
	uiAddIcon.x -= uiAddIcon.width * .5;
	uiAddButton.members.push(uiAddIcon);

	uiAddText = new FlxText(uiAddButton.x + 76, uiAddButton.y + 21);
	uiAddText.text = 'Add Event';
	uiAddText.alignment = 'center';
	uiAddText.size = 24;
	uiAddText.font = Paths.font('vcr.ttf');
	uiAddButton.members.push(uiAddText);

	topMenuSpr = new UITopMenu([
		{
			label: "File",
			childs: [
				{
					label: "New",
					onSelect: () ->
					{
						var s = new UIState();
						s.scriptName = "ut/AttackEditor";
						FlxG.switchState(s);
					}
				},
				{
					label: "Open",
					onSelect: () ->
					{
						fileDialog.onOpen.add((bytes) ->
						{
							var s = new UIState();
							s.scriptName = "ut/AttackEditor";
							FlxG.switchState(s);
							var shit = Json.parse(bytes.toString());
							fileEvents = shit.events;
						}, true);
						fileDialog.open('*json', null, 'Attack File');
					},
				},
				{
					label: "Save As...",
					onSelect: () ->
					{
						openSubState(new SaveSubstate(Json.stringify({
							events: events
						}), {
							defaultSaveFile: 'battleSaving.json'
						}));
					}
				},
				null,
				{
					label: "Exit",
					onSelect: (t) -> _exit()
				}
			]
		},
		{
			label: "Song",
			childs: [
				{
					label: "Switch",
					onSelect: () ->
					{
						var win = new UISubstateWindow(true, 'ut/editor/SongSelector');
						openSubState(win);
					}
				}
			]
		},
		{
			label: "Quants",
			childs: [
				{
					label: '1 >',
					onSelect: (t) ->
					{
						curQuant = 1;
					}
				},
				{
					label: '2 >',
					onSelect: (t) ->
					{
						curQuant = 2;
					}
				},
				{
					label: '4 >',
					onSelect: (t) ->
					{
						curQuant = 4;
					}
				},
				{
					label: '8 >',
					onSelect: (t) ->
					{
						curQuant = 8;
					}
				},
				{
					label: '16 >',
					onSelect: (t) ->
					{
						curQuant = 16;
					}
				},
				{
					label: '32 >',
					onSelect: (t) ->
					{
						curQuant = 32;
					}
				},
				{
					label: '64 >',
					onSelect: (t) ->
					{
						curQuant = 64;
					}
				},
				{
					label: '128 >',
					onSelect: (t) ->
					{
						curQuant = 128;
					}
				}
			]
		},
		{
			label: "Playtest",
			childs: [
				{
					label: "Playtest",
					onSelect: (t) ->
					{
						startTime = music.time;

						CoolUtil.safeSaveFile(TEMP_PATH, Json.stringify({
							events: events
						}));

						PlayState.loadSong(songName, 'normal', false, false);
						FlxG.switchState(new PlayState());

						fromEditor = true;
					}
				}
			]
		}

	]);
	uiGroup.add(topMenuSpr);

	uiContextPopups = [
		{
			label: "Edit",
			childs: [
				{
					label: "Undo",
					keybind: [FlxKey.CONTROL, FlxKey.Z],
					onSelect: runUndo
				},
				{
					label: "Redo",
					keybind: [FlxKey.CONTROL, FlxKey.Y],
					onSelect: runRedo
				},
				{
					label: "Add Event",
					keybind: [FlxKey.CONTROL, FlxKey.N],
					onSelect: _ui_addEvent
				}
			]
		},
		{
			label: 'Single Selection Options',
			childs: [
				{
					label: "Edit",
					keybind: [FlxKey.SHIFT, FlxKey.E],
					onSelect: (t) ->
					{
						if (slItems.length == 1)
							_ui_edit_event(slItems[0]);
					}
				},
				{
					label: 'Copy',
					keybind: [FlxKey.CONTROL, FlxKey.C],
					onSelect: _ui_copy
				},
				{
					label: 'Delete',
					keybind: [FlxKey.DELETE],
					onSelect: (t) ->
					{
						var item = slItems[0];

						_ui_delete_event(item.data);

						addToUndo({
							type: CSingleDelete,
							data: item.data
						});
						clearSelection();
					}
				},
				{
					label: "Snap to Grid",
					onSelect: (t) ->
					{
						snapEvents(slItems);
					}
				},
				{
					label: 'Save Preset',
					keybind: [FlxKey.CONTROL, FlxKey.P],
					onSelect: () ->
					{
						var pussy = [];
						for (penis in slItems)
							pussy.push(penis.data);
						_ui_add_preset(pussy);
					}
				}
			]
		},
		{
			label: 'Selection Options',
			childs: [
				{
					label: 'Copy',
					keybind: [FlxKey.CONTROL, FlxKey.C],
					onSelect: _ui_copy
				},
				{
					label: 'Delete',
					keybind: [FlxKey.DELETE],
					onSelect: (t) ->
					{
						var shits = [];
						for (item in slItems)
						{
							_ui_delete_event(item.data);

							shits.push(item.data);
						}
						addToUndo({
							type: CStackDelete,
							data: shits
						});
						clearSelection();
					}
				},
				{
					label: "Snap to Grid",
					onSelect: (t) ->
					{
						snapEvents(slItems);
					}
				},
				{
					label: 'Save Preset',
					keybind: [FlxKey.CONTROL, FlxKey.P],
					onSelect: () ->
					{
						var pussy = [];
						for (penis in slItems)
							pussy.push(penis.data);
						_ui_add_preset(pussy);
					}
				}
			]
		},
		{
			label: 'Group',
			childs: [
				{
					label: 'Clear Clipboard',
					keybind: [FlxKey.CONTROL, FlxKey.Q],
					onSelect: _ui_clear_pasting
				},
				{
					label: 'Paste',
					keybind: [FlxKey.CONTROL, FlxKey.V],
					onSelect: _ui_paste
				},
				{
					label: 'Save Preset',
					keybind: [FlxKey.CONTROL, FlxKey.P],
					onSelect: () ->
					{
						var pussy = [];
						for (penis in slItems)
							pussy.push(penis.data);
						_ui_add_preset(pussy);
					}
				}
			]
		},
		{
			label: 'Preset Options',
			childs: [
				{
					label: 'Cancel',
					keybind: [FlxKey.Q],
					onSelect: () ->
					{
						presetQueue = false;
						presetClipboard = null;
					}
				},
				{
					label: 'Paste',
					keybind: [FlxKey.CONTROL, FlxKey.V],
					onSelect: () ->
					{
						isCopying = true;
						copyList = [for (preset in presetClipboard.data) preset];
						_ui_paste();
						isCopying = false;

						presetQueue = false;
						presetClipboard = null;
					}
				}
			]
		}
	];

	updateUI(0);

	editorWatermark = new FlxText(0, 40, FlxG.width - 10);
	editorWatermark.alignment = 'right';
	editorWatermark.size = 16;
	editorWatermark.font = Paths.font('vcr.ttf');
	editorWatermark.text = 'Attack Editor [PROTOTYPE Functionality is subject to change]\n\nBuilt exclusively for use in \'Funktale: Rebreath\'';
	uiGroup.add(editorWatermark);
}

function getContextAction()
{
	if (slBoxState == B_SELECTED)
		return slItems.length == 1 ? 1 : 2;
	else if (isCopying)
		return 3;
	else if (presetQueue)
		return 4;
	return 0;
}

static function checkForID(type, id)
{
	return (hashList.get(type)?.indexOf(id) ?? -1) != -1;
}

function _ui_delete_event(event)
{
	if (hasheableEvents.contains(event.type))
	{
		hashList.get(event.type).remove(event.params[0].id);
		trace('Removed hash from $' + event.type + ': ' + event.params[0].id);
	}

	switch (event.type)
	{
		case EVENT_BONE:
			boneEvents.remove(event);
		case EVENT_BLASTER:
			blasterEvents.remove(event);
		case EVENT_EDIT_BONE:
			editBoneEvents.remove(event);
		case EVENT_EDIT_BOX:
			editBoxEvents.remove(event);
		case EVENT_EDIT_SOUL:
			editSoulEvents.remove(event);
		case EVENT_PLATFORM:
			platformEvents.remove(event);
		case EVENT_EDIT_PLATFORM:
			editPlatformEvents.remove(event);
	}

	events.remove(event);
}

function _ui_copy()
{
	copyList = [];
	if (!slBoxState == B_SELECTED)
		return;

	for (item in slItems)
		copyList.push(Reflect.copy(item.data));

	isCopying = true;

	trace('Copied');
}

// used for pasting
var queueSelect = [];

function _ui_paste(?noUndo)
{
	if (!isCopying)
		return;
	queueSelect = [];

	clearSelection();

	copyList.sort(function(a, b) return Reflect.compare(a.time, b.time));

	final pasteTime = getTimeFromWorldY(uiGridGrabber.y);
	final firstTime = copyList[0].time;
	final offsetTime = pasteTime - firstTime;

	final pasteRow = uiCurrentGridRow;
	final firstRow = 0;

	for (a in copyList)
		if (a.row < firstRow)
			firstRow = a.row;

	final offsetRow = pasteRow - firstRow;

	for (shit in eventSprites)
	{
		shit.selected = false;
		shit.color = 0xFFFFFFFF;
	}

	var changedIds = ['a' => 0];
	changedIds.remove('a');

	for (original in copyList)
	{
		var newEvent = Reflect.copy(original);
		newEvent.params = [Reflect.copy(original.params[0])];

		// "smart" new hash founder
		// i dont think this is fully smart tho
		if (newEvent.params != null && newEvent.params.length > 0 && Reflect.hasField(newEvent.params[0], "id"))
		{
			if (hasheableEvents.contains(newEvent.type))
			{
				var desiredID = newEvent.params[0].id;

				while (checkForID(newEvent.type, desiredID))
				{
					desiredID = desiredID + '_copy';
				}
				changedIds.set(newEvent.params[0].id, desiredID);
				newEvent.params[0].id = desiredID;
			}
			else if (editableEvents.contains(newEvent.type))
			{
				var desiredID = changedIds.get(newEvent.params[0].id);

				if (desiredID == null)
				{
					var desiredID = newEvent.params[0].id;

					while (checkForID(newEvent.type, desiredID))
					{
						desiredID = desiredID + '_copy';
					}
				}
				newEvent.params[0].id = desiredID;
			}
		}

		newEvent.time = newEvent.time + offsetTime;
		newEvent.row = Math.min(GRID_COUNT - 1, newEvent.row + offsetRow);

		queueSelect.push(newEvent);
		addEvent(newEvent);
	}

	if (noUndo != true)
	{
		addToUndo({
			type: CStackPaste,
			data: queueSelect.copy()
		});
	}
}

function _ui_clear_pasting()
{
	clearSelection();

	isCopying = false;
}

function _ui_addEvent()
{
	music.pause();

	var win = new UISubstateWindow(true, 'ut/editor/EventPicker');
	openSubState(win);
}

function _ui_add_preset(attacks)
{
	var newPreset = {
		name: 'Example Preset',
		data: []
	};
	for (attack in attacks)
	{
		var newAttack = Reflect.copy(attack);
		newAttack.params = Reflect.copy(attack.params);
		if (newAttack.params != null && newAttack.params.length > 0 && Reflect.hasField(newAttack.params[0], "id"))
		{
			newAttack.params[0].id = newAttack.params[0].id + "_copy";
		}

		newPreset.data.push(newAttack);
	}

	presetInput = newPreset;

	var win = new UISubstateWindow(true, 'ut/editor/PresetCreation');
	openSubState(win);
}

function _ui_insert_preset(data)
{
	trace('added preset to clipboard !: ' + data.name);

	presetClipboard = data;
	presetQueue = true;

	_ui_clear_pasting();
}

function _ui_save_preset(button)
{
	openSubState(new SaveSubstate(Json.stringify(button.presetData), {
		defaultSaveFile: 'preset.json'
	}));

	trace('saved !');
}

function _ui_remove_preset(button)
{
	uiPresetBox.remove(button);
	trace('removed !');
}

function _ui_import_preset()
{
	fileDialog.onOpen.add((bytes) ->
	{
		var data = Json.parse(bytes.toString());

		createPresetButton(data);
	}, true);
	fileDialog.open('*json', null, 'Attack Preset');
}

public static function limitDecimal(n:Float):Float
{
	var rounded = Math.fround(n * 10) / 10;
	if (Math.floor(rounded) == rounded)
	{
		return Math.floor(rounded);
	}
	return rounded;
}

function _exit()
{
	startTime = 0;
	FlxG.switchState(new MainMenuState());
}

function sortEvents()
{
	// may be the cause of some glitches
	return;

	events.sort(function(a, b) return Reflect.compare(a.time, b.time));
	boneEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	blasterEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editBoneEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editBoxEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editSoulEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	platformEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
	editPlatformEvents.sort(function(a, b) return Reflect.compare(a.time, b.time));
}

// undo & redo stuff
// essentials
var CStackDelete = "stack_delete";
var CSingleDelete = "single_delete";
var CStackPaste = "stack_paste";
var CSingleAdd = "single_add";
var CSingleEdit = "single_edit";

// used for presets
var CStackAdd = "stack_add";

// drag
var CSingleDrag = "single_drag";
var CStackDrag = "stack_drag";
var CSingleSnap = "single_snap";
var CStackSnap = "stack_snap";

// list itself
var undoList:UndoList = new UndoList();

function addToUndo(command)
{
	trace('Added to undo: ' + command.type);
	undoList.addToUndo(command);
}

function runUndo()
{
	var command = undoList.undo();

	if (command == null)
		return;
	trace('Undoing: ' + command.type);

	switch (command.type)
	{
		case CStackDelete:
			clearSelection();

			queueSelect = [];

			var items = command.data;

			for (item in items)
			{
				addEvent(item);
				queueSelect.push(item);
			}
		case CSingleDelete:
			clearSelection();

			queueSelect = [];

			var item = command.data;

			addEvent(item);
			queueSelect.push(item);
		case CStackPaste:
			var items = command.data;

			clearSelection();

			for (item in items)
				_ui_delete_event(item);
		case CSingleAdd:
			clearSelection();

			_ui_delete_event(command.data);
		case CSingleEdit:
			final data = command.data;

			editEvent(data.oldEv, data.eIndex, data.eMIndex, data.eBHIndex);
		case CStackDrag:
			// _temporalDragInfo[i] = {
			// 	event: item2.data,
			// 	oldPos: item2.data.time,
			// 	newPos: 0
			// };

			var items = command.data;

			for (item in items)
			{
				final event = item.event;
				event.time = item.oldPos;
				event.row = item.oldRow;
			}
	}
}

function runRedo()
{
	var command = undoList.redo();

	if (command == null)
		return;
	trace('Redoing: ' + command.type);

	switch (command.type)
	{
		case CStackDelete:
			var items = command.data;

			clearSelection();

			for (item in items)
				_ui_delete_event(item);
		case CSingleDelete:
			clearSelection();

			_ui_delete_event(command.data);
		case CStackPaste:
			clearSelection();

			queueSelect = [];

			var items = command.data;

			for (item in items)
			{
				addEvent(item);
				queueSelect.push(item);
			}
		case CSingleAdd:
			addEvent(command.data);
		case CSingleEdit:
			final data = command.data;

			editEvent(data.newEv, data.eIndex, data.eMIndex, data.eBHIndex);
		case CStackDrag:
			// _temporalDragInfo[i] = {
			// 	event: item2.data,
			// 	oldPos: item2.data.time,
			// 	newPos: 0
			// };

			var items = command.data;

			for (item in items)
			{
				final event = item.event;
				event.time = item.newPos;
				event.row = item.newRow;
			}
	}
}

// FUCKING HELL TO CODE ZONE
final samplesPerSecond = 60;

// 	startTime:Float,
// 	tweenDur:Float,
// 	easeFunc:Float->Float,
// 	newVel:Float
function keyframeAlgorithm(startX, startVelocity, timeElapsed, keyframes)
{
	var x = startX;
	var currentVel = startVelocity;
	var currentTime = 0.0;

	for (key in keyframes)
	{
		var tweenStart = key.startTime;
		var tweenEnd = tweenStart + key.tweenDur;

		if (timeElapsed <= tweenStart)
		{
			// not there yet, just move with current vel
			var dt = timeElapsed - currentTime;
			if (dt > 0)
				x += currentVel * dt;
			return x;
		}

		// some time gap before this tween? move normally
		if (currentTime < tweenStart)
		{
			var dt = tweenStart - currentTime;
			x += currentVel * dt;
			currentTime = tweenStart;
		}
		var segSamples = Math.ceil(key.tweenDur * samplesPerSecond);

		if (timeElapsed < tweenEnd)
		{
			// tween still running, integrate up to now
			var dt = timeElapsed - currentTime;
			var deltaT = dt / segSamples;
			for (i in 0...segSamples)
			{
				var t0 = i * deltaT;
				var t1 = (i + 1) * deltaT;

				var tNorm0 = (currentTime + t0 - tweenStart) / key.tweenDur;
				var tNorm1 = (currentTime + t1 - tweenStart) / key.tweenDur;

				var eased0 = key.easeFunc(Math.min(tNorm0, 1));
				var eased1 = key.easeFunc(Math.min(tNorm1, 1));

				var vel0 = currentVel + (key.newVel - currentVel) * eased0;
				var vel1 = currentVel + (key.newVel - currentVel) * eased1;

				x += (vel0 + vel1) * 0.5 * deltaT;
			}
			return x;
		}
		else
		{
			// tween finished, integrate whole thing and update vel
			var dt = key.tweenDur;
			var deltaT = dt / segSamples;
			for (i in 0...segSamples)
			{
				var t0 = i * deltaT;
				var t1 = (i + 1) * deltaT;

				var tNorm0 = t0 / key.tweenDur;
				var tNorm1 = t1 / key.tweenDur;

				var eased0 = key.easeFunc(tNorm0);
				var eased1 = key.easeFunc(tNorm1);

				var vel0 = currentVel + (key.newVel - currentVel) * eased0;
				var vel1 = currentVel + (key.newVel - currentVel) * eased1;

				x += (vel0 + vel1) * 0.5 * deltaT;
			}
			currentTime = tweenEnd;
			currentVel = key.newVel;
		}
	}

	// done with all keyframes, move with last vel if any time left
	if (timeElapsed > currentTime)
	{
		x += currentVel * (timeElapsed - currentTime);
	}

	return x;
}

// this was fucking HELL TO ME, 1 SINGLE FUNCTION, TOOK 2 DAYS TO CONSTANT THINKING,
// EVEN WHEN I'VE OUT, EATING, SLEEPING, SHITTING, IN THESE 2 DAYS
// I WAS ALWAYS THINKING HOW THE FUCK CAN I DO THIS
// anyways, i managed to do it, somehow
