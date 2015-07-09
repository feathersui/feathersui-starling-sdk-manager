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
package services
{
	import events.LoadConfigurationServiceEventType;
	import events.ProgressEventData;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;

	import model.SDKManagerModel;

	import org.robotlegs.starling.mvcs.Actor;

	public class LoadConfigurationService extends Actor implements ILoadConfigurationService
	{
		private static const LOAD_IN_PROGRESS_ERROR:String = "Loading the Feathers SDK configuration data failed. Loading is already in progress.";
		private static const FILE_NOT_FOUND_ERROR:String = "Loading the Feathers SDK configuration data failed. The file was not found on the server.";
		private static const SECURITY_ERROR:String = "Loading the Feathers SDK configuration data failed. Security sandbox error.";
		private static const PARSE_CONFIGURATION_ERROR:String = "Loading the Feathers SDK configuration data failed. Cannot parse configuration file.";
		
		private static const LOAD_PROGRESS_LABEL:String = "Loading configuration data...";
		
		public static const CONFIGURATION_URL:String = "http://feathersui.com/sdk/feathers-sdk-manager/sdk-manager-config-1.0.xml";
		
		[Inject]
		public var sdkManagerModel:SDKManagerModel;
		
		private var _loader:URLLoader;
		
		public function get isActive():Boolean
		{
			return this._loader !== null;
		}
		
		public function loadConfiguration():void
		{
			this.sdkManagerModel.log("Loading configuration file: " + CONFIGURATION_URL);
			this.dispatchWith(LoadConfigurationServiceEventType.START);
			
			if(this.isActive)
			{
				this.dispatchWith(LoadConfigurationServiceEventType.ERROR, false, LOAD_IN_PROGRESS_ERROR);
				return;
			}
			
			this._loader = new URLLoader();
			this._loader.dataFormat = URLLoaderDataFormat.TEXT;
			this._loader.addEventListener(Event.COMPLETE, loader_completeHandler);
			this._loader.addEventListener(ProgressEvent.PROGRESS, loader_progressHandler);
			this._loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			this._loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			this._loader.load(new URLRequest(CONFIGURATION_URL));
		}
		
		private function cleanup():void
		{
			this._loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			this._loader.removeEventListener(ProgressEvent.PROGRESS, loader_progressHandler);
			this._loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			this._loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			this._loader = null;
		}
		
		private function loader_completeHandler(event:Event):void
		{
			this.sdkManagerModel.log("Configuration file loaded successfully.");
			try
			{
				var xml:XML = new XML(this._loader.data);
				this.sdkManagerModel.parseConfiguration(xml);
			} 
			catch(error:Error) 
			{
				this.sdkManagerModel.log(PARSE_CONFIGURATION_ERROR + " " + error);
				this.cleanup();
				this.dispatchWith(LoadConfigurationServiceEventType.ERROR, false, PARSE_CONFIGURATION_ERROR);
				return;
			}
			this.cleanup();
			this.sdkManagerModel.log("Configuration file parsed successfully.");
			this.dispatchWith(LoadConfigurationServiceEventType.COMPLETE);
		}
		
		private function loader_progressHandler(event:ProgressEvent):void
		{
			var progress:Number = event.bytesLoaded / event.bytesTotal;
			this.dispatchWith(LoadConfigurationServiceEventType.PROGRESS, false, new ProgressEventData(progress, LOAD_PROGRESS_LABEL));
		}
		
		private function loader_ioErrorHandler(event:IOErrorEvent):void
		{
			this.sdkManagerModel.log(FILE_NOT_FOUND_ERROR + " " + event);
			this.cleanup();
			this.dispatchWith(LoadConfigurationServiceEventType.ERROR, false, FILE_NOT_FOUND_ERROR);
		}
		
		private function loader_securityErrorHandler(event:SecurityErrorEvent):void
		{
			this.sdkManagerModel.log(SECURITY_ERROR + " " + event);
			this.cleanup();
			this.dispatchWith(LoadConfigurationServiceEventType.ERROR, false, SECURITY_ERROR);
		}
	}
}