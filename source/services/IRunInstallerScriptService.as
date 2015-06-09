package services
{
	public interface IRunInstallerScriptService
	{
		function get isActive():Boolean;
		function runInstallerScript():void;
	}
}