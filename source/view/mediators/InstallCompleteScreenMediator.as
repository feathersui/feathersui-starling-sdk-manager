package view.mediators
{
	import flash.desktop.NativeApplication;

	import org.robotlegs.starling.mvcs.Mediator;

	import starling.events.Event;

	import view.InstallCompleteScreen;

	public class InstallCompleteScreenMediator extends Mediator
	{
		[Inject]
		public var screen:InstallCompleteScreen;
		
		override public function onRegister():void
		{
			this.addViewListener(Event.COMPLETE, view_completeHandler);
		}
		
		private function view_completeHandler(event:Event):void
		{
			NativeApplication.nativeApplication.exit(0);
		}
	}
}
