import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.tile.FlxTilemap;
import openfl.util.Assets;

var data;
var map:FlxOgmo3Loader;
var walls:FlxTilemap;

function create()
{
	loadMap('ruins');
}

function loadMap(name)
{
	bgColor = 0xFF7C7C7C;
	camera.zoom = 1;
	trace('Loading map: ' + name);

	data = Json.parse(Assets.getText(Paths_tile('maps/' + name + '.json')));

	map = new FlxOgmo3Loader(Paths_tile('main.ogmo'), Paths_tile('maps/' + name + '.json'));
	
	var infoWall = getInfoBytileset('walls').tileset;

	walls = map.loadTilemapExt(getTileset(infoWall), 'walls');
	walls.follow();
	walls.setTileProperties(1, 0x00);
	walls.visible = true;
	add(walls);
}

function Paths_tile(str)
{
	return Paths.file('tiles/' + str);
}

function getTileset(name)
{
	return Paths_tile('textures/tiles/' + name + '.png');
}

function getInfoBytileset(tilesetLayerName:String)
{
	var layers = data.layers;
	for (layer in layers)
	{
		if (layer.name == tilesetLayerName)
		{
			return layer;
		}
	}
	return null;
}
