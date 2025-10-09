import Json;
import funkin.backend.MusicBeatTransition;
import funkin.editors.ui.UIState;
import funkin.menus.BetaWarningState;
import funkin.menus.FreeplayState;
import funkin.menus.MainMenuState;
import funkin.menus.TitleState;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;

static var constBoxWidth = 350;
static var constBoxHeight = 340;
static var constBoxX = (FlxG.width - constBoxWidth) / 2;
static var constBoxY = (FlxG.height - constBoxHeight) / 2 + 120;
static var constBoxThickness = 20;
static var fromEditor = false;

var redirectStates:Map<FlxState, String> = [
	// TitleState => "ut/RPGTest",
	TitleState => "ut/MainMenu",
	BetaWarningState => "ut/MainMenu",
	MainMenuState => "ut/MainMenu"
];

function new()
{
	MusicBeatTransition.script = "data/scripts/Transition";
}

function preStateSwitch()
{
	for (redirectState in redirectStates.keys())
	{
		if (fromEditor && Std.isOfType(FlxG.game._requestedState, FreeplayState))
		{
			var s = new UIState();
			s.scriptName = "ut/AttackEditor";

			if (FileSystem.exists(TEMP_PATH))
			{
				fileEvents = Json.parse(File.getContent(TEMP_PATH)).events;
				FileSystem.deleteFile(TEMP_PATH);
				trace('aa');
			}

			FlxG.game._requestedState = s;
			fromEditor = false;
		}
		if (Std.isOfType(FlxG.game._requestedState, redirectState))
		{
			FlxG.game._requestedState = new ModState(redirectStates.get(redirectState));
		}
	}
}
