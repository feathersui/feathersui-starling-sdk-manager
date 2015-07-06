/*
Feathers SDK Manager
Copyright 2015 Bowler Hat LLC

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
package commands
{
	import model.SDKManagerModel;

	import com.bowlerhatsoftware.analytics.GAMeasurementProtocol;
	import org.robotlegs.starling.mvcs.Command;

	import starling.events.Event;

	public class AnalyticsErrorCommand extends Command
	{
		[Inject]
		public var event:Event;
		
		[Inject]
		public var sdkManagerModel:SDKManagerModel;
		
		override public function execute():void
		{
			var errorType:String = this.event.type;
			var message:String = this.event.data as String;
			GAMeasurementProtocol.trackException(errorType + ": " + message, true);
		}
	}
}
