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
package
{
	import commands.AnalyticsInitCommand;

	import commands.AnalyticsErrorCommand;
	import commands.AnalyticsEventInstallCompleteCommand;

	import events.AcquireProductServiceEventType;
	import events.RunInstallScriptServiceEventType;

	import flash.desktop.NativeApplication;
	import flash.events.UncaughtErrorEvent;

	import model.SDKManagerModel;

	import org.robotlegs.starling.base.ContextEventType;
	import org.robotlegs.starling.mvcs.Context;

	import services.AcquireProductService;
	import services.IAcquireProductService;
	import services.ILoadConfigurationService;
	import services.IRunInstallerScriptService;
	import services.LoadConfigurationService;
	import services.RunInstallerScriptService;

	import starling.core.Starling;

	import view.ChooseInstallDirectoryScreen;
	import view.ChooseProductScreen;
	import view.ChooseRuntimeScreen;
	import view.ConfigureDownloadCacheScreen;
	import view.InstallCompleteScreen;
	import view.InstallErrorScreen;
	import view.InstallProgressScreen;
	import view.LicenseScreen;
	import view.LogsScreen;
	import view.mediators.ChooseInstallDirectoryScreenMediator;
	import view.mediators.ChooseProductScreenMediator;
	import view.mediators.ChooseRuntimeScreenMediator;
	import view.mediators.ConfigureDownloadCacheScreenMediator;
	import view.mediators.FeathersSDKManagerMediator;
	import view.mediators.InstallCompleteScreenMediator;
	import view.mediators.InstallErrorScreenMediator;
	import view.mediators.InstallProgressScreenMediator;
	import view.mediators.LicenseScreenMediator;
	import view.mediators.LogsScreenMediator;

	public class FeathersSDKManagerContext extends Context
	{
		public function FeathersSDKManagerContext(view:FeathersSDKManager = null)
		{
			super(view);
		}
		
		override public function startup():void
		{	
			this.injector.mapSingleton(SDKManagerModel);
			this.injector.mapSingletonOf(ILoadConfigurationService, LoadConfigurationService);
			this.injector.mapSingletonOf(IAcquireProductService, AcquireProductService);
			this.injector.mapSingletonOf(IRunInstallerScriptService, RunInstallerScriptService);
			
			var applicationDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = applicationDescriptor.namespace();
			var applicationVersion:String = applicationDescriptor.ns::versionNumber.toString();
			this.injector.mapValue(String, applicationVersion, "applicationVersion");
			
			CONFIG::USE_ANALYTICS
			{
				this.commandMap.mapEvent(ContextEventType.STARTUP_COMPLETE, AnalyticsInitCommand);
				this.commandMap.mapEvent(RunInstallScriptServiceEventType.COMPLETE, AnalyticsEventInstallCompleteCommand);
				this.commandMap.mapEvent(RunInstallScriptServiceEventType.ERROR, AnalyticsErrorCommand);
				this.commandMap.mapEvent(AcquireProductServiceEventType.ERROR, AnalyticsErrorCommand);
				this.commandMap.mapEvent(UncaughtErrorEvent.UNCAUGHT_ERROR, AnalyticsErrorCommand);
				Starling.current.nativeStage.root.loaderInfo.uncaughtErrorEvents.addEventListener(
					UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorEvents_uncaughtErrorEventHandler);
			}
			
			this.mediatorMap.mapView(FeathersSDKManager, FeathersSDKManagerMediator);
			this.mediatorMap.mapView(ChooseProductScreen, ChooseProductScreenMediator);
			this.mediatorMap.mapView(ChooseRuntimeScreen, ChooseRuntimeScreenMediator);
			this.mediatorMap.mapView(ChooseInstallDirectoryScreen, ChooseInstallDirectoryScreenMediator);
			this.mediatorMap.mapView(LicenseScreen, LicenseScreenMediator);
			this.mediatorMap.mapView(InstallProgressScreen, InstallProgressScreenMediator);
			this.mediatorMap.mapView(InstallErrorScreen, InstallErrorScreenMediator);
			this.mediatorMap.mapView(InstallCompleteScreen, InstallCompleteScreenMediator);
			this.mediatorMap.mapView(ConfigureDownloadCacheScreen, ConfigureDownloadCacheScreenMediator);
			this.mediatorMap.mapView(LogsScreen, LogsScreenMediator);
			
			this.dispatchEventWith(ContextEventType.STARTUP_COMPLETE);
		}
		
		private function uncaughtErrorEvents_uncaughtErrorEventHandler(event:UncaughtErrorEvent):void
		{
			var error:* = event.error;
			if(error is Error)
			{
				var errorError:Error = Error(error);
				this.dispatchEventWith(UncaughtErrorEvent.UNCAUGHT_ERROR, false, errorError.message);
			}
			else
			{
				this.dispatchEventWith(UncaughtErrorEvent.UNCAUGHT_ERROR, false, error);
			}
		}
	}
}