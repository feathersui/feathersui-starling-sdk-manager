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