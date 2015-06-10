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
package
{
	import model.InstallerModel;

	import org.robotlegs.starling.base.ContextEventType;
	import org.robotlegs.starling.mvcs.Context;

	import services.AcquireProductService;
	import services.IAcquireProductService;
	import services.ILoadConfigurationService;
	import services.IRunInstallerScriptService;
	import services.LoadConfigurationService;
	import services.RunInstallerScriptService;

	import view.ChooseInstallDirectoryScreen;
	import view.ChooseProductScreen;
	import view.ChooseRuntimeScreen;
	import view.ConfigureDownloadCacheScreen;
	import view.InstallCompleteScreen;
	import view.InstallErrorScreen;
	import view.InstallProgressScreen;
	import view.LicenseScreen;
	import view.mediators.ChooseInstallDirectoryScreenMediator;
	import view.mediators.ChooseProductScreenMediator;
	import view.mediators.ChooseRuntimeScreenMediator;
	import view.mediators.ConfigureDownloadCacheScreenMediator;
	import view.mediators.FeathersSDKInstallerMediator;
	import view.mediators.InstallCompleteScreenMediator;
	import view.mediators.InstallErrorScreenMediator;
	import view.mediators.InstallProgressScreenMediator;
	import view.mediators.LicenseScreenMediator;

	public class FeathersSDKInstallerContext extends Context
	{
		public function FeathersSDKInstallerContext(view:FeathersSDKInstaller = null)
		{
			super(view);
		}
		
		override public function startup():void
		{	
			this.injector.mapSingleton(InstallerModel);
			this.injector.mapSingletonOf(ILoadConfigurationService, LoadConfigurationService);
			this.injector.mapSingletonOf(IAcquireProductService, AcquireProductService);
			this.injector.mapSingletonOf(IRunInstallerScriptService, RunInstallerScriptService);
			
			this.mediatorMap.mapView(FeathersSDKInstaller, FeathersSDKInstallerMediator);
			this.mediatorMap.mapView(ChooseProductScreen, ChooseProductScreenMediator);
			this.mediatorMap.mapView(ChooseRuntimeScreen, ChooseRuntimeScreenMediator);
			this.mediatorMap.mapView(ChooseInstallDirectoryScreen, ChooseInstallDirectoryScreenMediator);
			this.mediatorMap.mapView(LicenseScreen, LicenseScreenMediator);
			this.mediatorMap.mapView(InstallProgressScreen, InstallProgressScreenMediator);
			this.mediatorMap.mapView(InstallErrorScreen, InstallErrorScreenMediator);
			this.mediatorMap.mapView(InstallCompleteScreen, InstallCompleteScreenMediator);
			this.mediatorMap.mapView(ConfigureDownloadCacheScreen, ConfigureDownloadCacheScreenMediator);
			
			this.dispatchEventWith(ContextEventType.STARTUP_COMPLETE);
		}
	}
}