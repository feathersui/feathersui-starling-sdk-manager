package view.mediators
{
	import model.InstallerModel;

	import org.robotlegs.starling.mvcs.Mediator;

	import starling.events.Event;

	import view.ChooseInstallDirectoryScreen;

	public class ChooseInstallDirectoryScreenMediator extends Mediator
	{
		[Inject]
		public var installerModel:InstallerModel;
		
		[Inject]
		public var screen:ChooseInstallDirectoryScreen;
		
		override public function onRegister():void
		{
			//since the user may navigate back, we may need to repopulate the
			//appropriate fields in this screen.
			this.screen.installDirectory = this.installerModel.installDirectory;
			this.addViewListener(Event.COMPLETE, view_completeHandler);
		}
		
		private function view_completeHandler(event:Event):void
		{
			this.installerModel.installDirectory = this.screen.installDirectory;
		}
	}
}