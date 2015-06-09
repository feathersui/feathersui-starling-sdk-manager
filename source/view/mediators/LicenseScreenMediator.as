package view.mediators
{
	import model.InstallerModel;

	import org.robotlegs.starling.mvcs.Mediator;

	import services.IAcquireProductService;

	import starling.events.Event;

	import view.LicenseScreen;

	public class LicenseScreenMediator extends Mediator
	{
		[Inject]
		public var screen:LicenseScreen;
		
		[Inject]
		public var installerModel:InstallerModel;
		
		[Inject]
		public var binaryService:IAcquireProductService;
		
		override public function onRegister():void
		{
			this.screen.licenses = this.installerModel.licenses;
			this.addViewListener(Event.COMPLETE, view_completeHandler);
		}
		
		private function view_completeHandler(event:Event):void
		{
			this.binaryService.acquireSelectedProduct();
		}
	}
}