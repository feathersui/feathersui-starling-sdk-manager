package view.mediators
{
	import events.AcquireProductServiceEventType;
	import events.ProgressEventData;
	import events.RunInstallScriptServiceEventType;

	import org.robotlegs.starling.mvcs.Mediator;

	import services.IAcquireProductService;
	import services.IRunInstallerScriptService;

	import starling.events.Event;

	import view.InstallProgressScreen;

	public class InstallProgressScreenMediator extends Mediator
	{
		private static const ACQUIRE_BINARY_DISTRIBUTION_TITLE:String = "Downloading Feathers SDK";
		private static const RUN_INSTALLER_SCRIPT_TITLE:String = "Installing Feathers SDK";
		
		[Inject]
		public var screen:InstallProgressScreen;
		
		[Inject]
		public var installerService:IRunInstallerScriptService;
		
		[Inject]
		public var binaryService:IAcquireProductService;
		
		override public function onRegister():void
		{
			this.updateTitle();
			this.screen.progressValue = 0;
			this.screen.progressText = null;
			this.addContextListener(AcquireProductServiceEventType.START, context_acquireBinaryDistributionStartHandler);
			this.addContextListener(AcquireProductServiceEventType.PROGRESS, context_acquireBinaryDistributionProgressHandler);
			this.addContextListener(RunInstallScriptServiceEventType.START, context_runInstallerScriptStartHandler);
			this.addContextListener(RunInstallScriptServiceEventType.PROGRESS, context_runInstallerScriptProgressHandler);
		}
		
		private function updateTitle():void
		{
			if(this.binaryService.isActive)
			{
				this.screen.progressTitle = ACQUIRE_BINARY_DISTRIBUTION_TITLE;
			}
			else
			{
				this.screen.progressTitle = RUN_INSTALLER_SCRIPT_TITLE;
			}
		}
		
		private function context_acquireBinaryDistributionStartHandler(event:Event):void
		{
			this.updateTitle();
		}
		
		private function context_acquireBinaryDistributionProgressHandler(event:Event, data:ProgressEventData):void
		{
			this.screen.progressValue = data.progress;
			this.screen.progressText = data.label;
		}
		
		private function context_runInstallerScriptStartHandler(event:Event):void
		{
			this.updateTitle();
		}
		
		private function context_runInstallerScriptProgressHandler(event:Event, data:ProgressEventData):void
		{
			this.screen.progressValue = data.progress;
			this.screen.progressText = data.label;
		}
	}
}