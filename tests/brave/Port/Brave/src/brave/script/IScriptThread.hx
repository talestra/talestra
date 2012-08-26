package brave.script;

/**
 * ...
 * @author 
 */

interface IScriptThread 
{
	function execute():Void;
	function getSpecial(index:Int):Dynamic;
	function getVariable(index:Int):Variable;
}