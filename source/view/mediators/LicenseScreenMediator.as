/*
Copyright 2015 Joshua Tynjala

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
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