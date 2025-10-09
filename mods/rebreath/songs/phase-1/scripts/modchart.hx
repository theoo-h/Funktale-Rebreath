import modchart.Config;
import modchart.Manager;

var modchart:Manager;

function postCreate()
{
	modchart = new Manager();
	add(modchart);
}
