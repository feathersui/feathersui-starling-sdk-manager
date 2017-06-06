/*
Feathers SDK Manager
Copyright 2015 Bowler Hat LLC
Portions Copyright 2014 The Apache Software Foundation

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
	import events.ProgressEventData;
	import events.RunInstallScriptServiceEventType;

	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	import model.SDKManagerModel;
	import model.RuntimeConfigurationItem;

	import org.apache.flex.ant.Ant;
	import org.apache.flex.ant.tags.Checksum;
	import org.apache.flex.ant.tags.Copy;
	import org.apache.flex.ant.tags.Get;
	import org.robotlegs.starling.mvcs.Actor;

	import starling.core.Starling;
	import starling.events.Event;

	public class RunInstallerScriptService extends Actor implements IRunInstallerScriptService
	{
		private static const INSTALLATION_IN_PROGRESS_ERROR:String = "Installation of the Feathers SDK failed. An installation is already in progress.";
		private static const NO_RUNTIME_SELECTED_ERROR:String = "Downloading the Feathers SDK failed. No runtime is selected.";
		private static const MISSING_SCRIPT_ERROR:String = "Installation of the Feathers SDK failed. Cannot find SDK installer script.";
		private static const UNKNOWN_ERROR:String = "Installation of the Feathers SDK failed due to an unexpected error.";
		
		private static const COPY_TASK_PROGRESS_LABEL:String = "Copying files...";
		private static const GET_TASK_PROGRESS_LABEL:String = "Downloading file...";
		private static const CHECKSUM_TASK_PROGRESS_LABEL:String = "Verifying checksum...";
		
		[Inject]
		public var sdkManagerModel:SDKManagerModel;
		
		private var _ant:Ant;
		
		public function get isActive():Boolean
		{
			return this._ant !== null;
		}
		
		public function runInstallerScript():void
		{
			this.dispatchWith(RunInstallScriptServiceEventType.START);
			
			if(this.isActive)
			{
				this.sdkManagerModel.log(INSTALLATION_IN_PROGRESS_ERROR);
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, INSTALLATION_IN_PROGRESS_ERROR);
				return;
			}
			
			if(this.sdkManagerModel.selectedRuntime === null)
			{
				this.sdkManagerModel.log(NO_RUNTIME_SELECTED_ERROR);
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, NO_RUNTIME_SELECTED_ERROR);
				return;
			}

			this.eventDispatcher.addEventListener(RunInstallScriptServiceEventType.CANCEL, context_runInstallerScriptCancelHandler);
			
			this._ant = new Ant();
			this._ant.output = this.sdkManagerModel.log;
			var installDirectory:File = this.sdkManagerModel.installDirectory;
			var installerScriptFile:File = installDirectory.resolvePath("installer.xml");
			Starling.current.stage.addEventListener(starling.events.Event.ENTER_FRAME, enterFrameHandler);
			var context:Object =
			{
				"installer": true,
				"do.air.install": true,
				"do.flash.install": true,
				"do.swfobject.install": true,
				"do.fontswf.install": true
			};
			
			var downloadCacheEnabled:Boolean = this.sdkManagerModel.downloadCacheEnabled;
			if(downloadCacheEnabled)
			{
				context["usingDownloadCache"] = downloadCacheEnabled;
				context["downloadCacheFolder"] = this.sdkManagerModel.downloadCacheDirectory.nativePath;
			}
			var configFile:File = this.sdkManagerModel.configurationFile;
			if(configFile && configFile.exists)
			{
				context["xml.properties"] = configFile.url;
			}
			
			var selectedRuntime:RuntimeConfigurationItem = this.sdkManagerModel.selectedRuntime;
			context["air.sdk.version"] = selectedRuntime.airVersionNumber;
			context["flash.sdk.version"] = selectedRuntime.playerGlobalVersionNumber;
			
			this.sdkManagerModel.log("Installing with script: " + installerScriptFile.nativePath);
			this.sdkManagerModel.log("AIR SDK version: " + selectedRuntime.airVersionNumber);
			this.sdkManagerModel.log("playerglobal.swc version: " + selectedRuntime.playerGlobalVersionNumber);
			this.sdkManagerModel.log("Download cache: " + (downloadCacheEnabled ? this.sdkManagerModel.downloadCacheDirectory.nativePath : "Disabled"));
			if(installerScriptFile.exists && !this._ant.processXMLFile(installerScriptFile, context, true))
			{
				this._ant.addEventListener(flash.events.Event.COMPLETE, ant_completeHandler);
				this._ant.addEventListener(ProgressEvent.PROGRESS, ant_progressHandler);
			}
			else
			{
				this.sdkManagerModel.log(MISSING_SCRIPT_ERROR);
				this.cleanupInstallation(false, true, MISSING_SCRIPT_ERROR);
			}
		}
		
		protected function cleanupInstallation(userCancel:Boolean, isError:Boolean, errorMessage:String = null):void
		{
			this.eventDispatcher.removeEventListener(RunInstallScriptServiceEventType.CANCEL, context_runInstallerScriptCancelHandler);
			Starling.current.stage.removeEventListener(starling.events.Event.ENTER_FRAME, enterFrameHandler);

			if(this._ant)
			{
				this._ant.removeEventListener(flash.events.Event.COMPLETE, ant_completeHandler);
				this._ant.removeEventListener(ProgressEvent.PROGRESS, ant_progressHandler);
			}

			if(userCancel || isError)
			{
				//delete the files that we put in the installation directory
				//because the SDK will be in a bad state.
				var installDirectory:File = this.sdkManagerModel.installDirectory;
				if(installDirectory.exists && installDirectory.isDirectory)
				{
					var files:Array = installDirectory.getDirectoryListing();
					for each(var file:File in files)
					{
						if(file.isDirectory)
						{
							file.deleteDirectory(true);
						}
						else
						{
							file.deleteFile();
						}
					}
				}
			}
			if(isError)
			{
				if(errorMessage === null)
				{
					errorMessage = UNKNOWN_ERROR;
				}
				this.sdkManagerModel.log(errorMessage);
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, errorMessage);
			}
		}
		
		private function enterFrameHandler(event:starling.events.Event):void
		{
			this._ant.doCallback();
		}
		
		private function ant_completeHandler(event:flash.events.Event):void
		{
			if(this._ant)
			{
				if(this._ant.project.status)
				{
					//success!
					this.cleanupInstallation(false, false);
					this.sdkManagerModel.log("Installation completed successfully.");
					this.dispatchWith(RunInstallScriptServiceEventType.COMPLETE);
					return;
				}
				var failureMessage:String = this._ant.project.failureMessage;
				if(failureMessage)
				{
					this.cleanupInstallation(false, true, failureMessage);
				}
				else
				{
					this.cleanupInstallation(false, true);
				}
			}
			else //something went terribly wrong and we lost ant
			{
				this.cleanupInstallation(false, true);
			}
		}
		
		private function ant_progressHandler(event:ProgressEvent):void
		{
			var progressLabel:String = "Installing...";
			var progressValue:Number = Number.POSITIVE_INFINITY;
			var progressClass:Object = this._ant.progressClass;
			if(progressClass && event.bytesTotal !== 0)
			{
				progressValue = event.bytesLoaded / event.bytesTotal;
			}
			if(progressValue < 1)
			{
				//we check for < 1 because we want to switch to the spinner
				//animation once we finish the current task with progress
				switch(progressClass.constructor)
				{
					case Copy:
					{
						progressLabel = COPY_TASK_PROGRESS_LABEL;
						break;
					}
					case Get:
					{
						progressLabel = GET_TASK_PROGRESS_LABEL;
						break;
					}
					case Checksum:
					{
						progressLabel = CHECKSUM_TASK_PROGRESS_LABEL;
						break;
					}
				}
			}
			this.dispatchWith(RunInstallScriptServiceEventType.PROGRESS, false,
				new ProgressEventData(progressValue, progressLabel));
		}
		
		private function context_runInstallerScriptCancelHandler(event:starling.events.Event):void
		{
			this.cleanupInstallation(true, false);
		}
	}
}

//this needs to be referenced somewhere to bring in all of the ant tasks.
AntClasses;