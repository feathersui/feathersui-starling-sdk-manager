package view.mediators
{
	import model.InstallerModel;

	import org.robotlegs.starling.mvcs.Mediator;

	import starling.events.Event;

	import view.ConfigureDownloadCacheScreen;

	public class ConfigureDownloadCacheScreenMediator extends Mediator
	{
		[Inject]
		public var installerModel:InstallerModel;
		
		[Inject]
		public var screen:ConfigureDownloadCacheScreen;
		
		override public function onRegister():void
		{
			//since the user may navigate back, we may need to repopulate the
			//appropriate fields in this screen.
			this.screen.downloadCacheEnabled = this.installerModel.downloadCacheEnabled;
			this.screen.downloadCacheDirectory = this.installerModel.downloadCacheDirectory;
			this.addViewListener(Event.COMPLETE, view_completeHandler);
		}
		
		private function view_completeHandler(event:Event):void
		{
			this.installerModel.downloadCacheEnabled = this.screen.downloadCacheEnabled;
			this.installerModel.downloadCacheDirectory = this.screen.downloadCacheDirectory;
		}
	}
}


