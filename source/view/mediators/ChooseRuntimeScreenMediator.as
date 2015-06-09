package view.mediators
{
	import model.InstallerModel;

	import org.robotlegs.starling.mvcs.Mediator;

	import starling.events.Event;

	import view.ChooseRuntimeScreen;

	public class ChooseRuntimeScreenMediator extends Mediator
	{
		[Inject]
		public var installerModel:InstallerModel;
		
		[Inject]
		public var screen:ChooseRuntimeScreen;
		
		override public function onRegister():void
		{
			//since the user may navigate back, we may need to repopulate the
			//appropriate fields in this screen.
			this.screen.runtimes = this.installerModel.runtimes;
			this.screen.selectedRuntime = this.installerModel.selectedRuntime;
			this.addViewListener(Event.COMPLETE, view_completeHandler);
		}
		
		private function view_completeHandler(event:Event):void
		{
			this.installerModel.selectedRuntime = this.screen.selectedRuntime;
		}
	}
}