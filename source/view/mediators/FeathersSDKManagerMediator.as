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
package view.mediators
{
	import events.AcquireProductServiceEventType;
	import events.LoadConfigurationServiceEventType;
	import events.RunInstallScriptServiceEventType;

	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.controls.StackScreenNavigatorItem;
	import feathers.core.PopUpManager;
	import feathers.layout.AnchorLayout;

	import flash.display.Stage;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;

	import model.SDKManagerModel;

	import org.robotlegs.starling.mvcs.Mediator;

	import services.ILoadConfigurationService;
	import services.IRunInstallerScriptService;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.events.Event;

	import utils.CustomStyleNames;

	public class FeathersSDKManagerMediator extends Mediator
	{
		private static const NO_ACTIVE_NETWORK_ERROR:String = "Cannot install the Feathers SDK at this time. Please check your Internet connection.";
		
		private static const DEFAULT_UPDATE_URL:String = "http://feathersui.com/sdk/feathers-sdk-manager/";
		
		[Inject]
		public var navigator:FeathersSDKManager;
		
		[Inject]
		public var sdkManagerModel:SDKManagerModel;
		
		[Inject]
		public var installerService:IRunInstallerScriptService;
		
		[Inject]
		public var configService:ILoadConfigurationService;
		
		[Inject(name="applicationVersion")]
		public var applicationVersion:String;
		
		private var _contextMenu:ContextMenu;
		
		private var _allowContextMenu:Boolean = false;
		
		override public function onRegister():void
		{
			this.addContextListener(LoadConfigurationServiceEventType.ERROR, context_loadConfigurationErrorHandler);
			this.addContextListener(LoadConfigurationServiceEventType.COMPLETE, context_loadConfigurationCompleteHandler);
			
			this.addContextListener(AcquireProductServiceEventType.START, context_acquireBinaryDistributionStartHandler);
			this.addContextListener(AcquireProductServiceEventType.ERROR, context_acquireBinaryDistributionErrorHandler);
			this.addContextListener(AcquireProductServiceEventType.COMPLETE, context_acquireBinaryDistributionCompleteHandler);
			
			this.addContextListener(RunInstallScriptServiceEventType.START, context_runInstallerScriptStartHandler);
			this.addContextListener(RunInstallScriptServiceEventType.ERROR, context_runInstallerScriptErrorHandler);
			this.addContextListener(RunInstallScriptServiceEventType.COMPLETE, context_runInstallerScriptCompleteHandler);
			
			Starling.current.nativeStage.nativeWindow.addEventListener(flash.events.Event.CLOSING, nativeWindow_closingHandler, false, 0, true);
			
			this.createContextMenu();
			
			if(this.checkNetwork())
			{
				this.configService.loadConfiguration();
			}
			else
			{
				var item:StackScreenNavigatorItem = this.navigator.installError;
				item.properties.errorMessage = NO_ACTIVE_NETWORK_ERROR;
				this.navigator.rootScreenID = FeathersSDKManager.SCREEN_ID_INSTALL_ERROR;
			}
		}
		
		override public function onRemove():void
		{
			var nativeStage:Stage = Starling.current.nativeStage;
			nativeStage.nativeWindow.removeEventListener(flash.events.Event.CLOSING, nativeWindow_closingHandler);
			nativeStage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, nativeStage_rightMouseDownHandler);
		}
		
		private function createContextMenu():void
		{
			this._contextMenu = new ContextMenu();
			this._contextMenu.hideBuiltInItems();
			
			var downloadCacheMenuItem:ContextMenuItem = new ContextMenuItem("Configure Download Cache...");
			downloadCacheMenuItem.checked = this.sdkManagerModel.downloadCacheEnabled;
			downloadCacheMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, downloadCacheMenuItem_menuItemSelectHandler);
			this._contextMenu.customItems.push(downloadCacheMenuItem);
			
			//this is a hack so that the context menu owner doesn't steal focus
			//from Feathers components. the context menu owner will only be
			//shown when the right-mouse button is down.
			Starling.current.nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, nativeStage_rightMouseDownHandler, false, 0, true);
		}
		
		private function checkNetwork():Boolean
		{
			var hasActiveNetwork:Boolean = false;
			var networkAdapters:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();
			for each(var networkAdapter:NetworkInterface in networkAdapters)
			{
				if(networkAdapter.active)
				{
					hasActiveNetwork = true;
					break;
				}
			}
			return hasActiveNetwork;
		}
		
		private function checkForUpdate():void
		{
			var latestVersionParts:Array = this.sdkManagerModel.latestVersion.split(".");
			var currentVersionParts:Array = this.applicationVersion.split(".");
			var partsCount:int = currentVersionParts.length;
			if(latestVersionParts.length !== partsCount)
			{
				//something went wrong while parsing the version numbers
				return;
			}
			var hasUpdate:Boolean = false;
			for(var i:int = 0; i < partsCount; i++)
			{
				var currentPart:int = parseInt(currentVersionParts[i] as String, 10);
				var latestPart:int = parseInt(latestVersionParts[i] as String, 10);
				if(latestPart > currentPart)
				{
					hasUpdate = true;
					break;
				}
			}
			if(hasUpdate)
			{
				var container:LayoutGroup = new LayoutGroup();
				container.autoSizeMode = LayoutGroup.AUTO_SIZE_MODE_STAGE;
				container.layout = new AnchorLayout();
				var updateButton:Button = new Button();
				updateButton.styleNameList.add(CustomStyleNames.ALTERNATE_STYLE_NAME_UPDATE_BUTTON);
				updateButton.label = "New SDK Manager Update!";
				this.eventMap.mapListener(updateButton, starling.events.Event.TRIGGERED, updateButton_triggeredHandler);
				container.addChild(updateButton);
				PopUpManager.addPopUp(container, false, false);
				container.validate();
				updateButton.includeInLayout = false;
				var y:Number = updateButton.y;
				updateButton.y = -updateButton.height;
				var tween:Tween = Tween(Starling.juggler.tween(updateButton, 0.5, {y: y}));
				tween.delay = 0.5;
				tween.roundToInt = true;
				tween.transition = Transitions.EASE_OUT_BACK;
				tween.onComplete = function():void
				{
					updateButton.includeInLayout = true;
				}
			}
		}
		
		private function updateButton_triggeredHandler(event:starling.events.Event):void
		{
			navigateToURL(new URLRequest(DEFAULT_UPDATE_URL), "_blank");
		}
		
		private function nativeStage_rightMouseDownHandler(event:MouseEvent):void
		{
			if(!this._allowContextMenu || this.navigator.activeScreenID === FeathersSDKManager.SCREEN_ID_DOWNLOAD_CACHE)
			{
				return;
			}
			this._contextMenu.display(Starling.current.nativeStage, event.stageX, event.stageY);
		}
		
		private function nativeWindow_closingHandler(event:flash.events.Event):void
		{
			if(this.navigator.activeScreenID == FeathersSDKManager.SCREEN_ID_INSTALL_PROGRESS)
			{
				//we don't want to interrupt the installation
				event.preventDefault();
			}
		}
		
		private function context_loadConfigurationErrorHandler(event:starling.events.Event, errorMessage:String):void
		{
			var item:StackScreenNavigatorItem = this.navigator.installError;
			item.properties.errorMessage = errorMessage;
			this.navigator.rootScreenID = FeathersSDKManager.SCREEN_ID_INSTALL_ERROR;
		}
		
		private function context_loadConfigurationCompleteHandler(event:starling.events.Event):void
		{
			this.checkForUpdate();
			this._allowContextMenu = true;
			this.navigator.rootScreenID = FeathersSDKManager.SCREEN_ID_CHOOSE_PRODUCT;
		}
		
		private function context_acquireBinaryDistributionStartHandler(event:starling.events.Event):void
		{
			this._allowContextMenu = false;
			this.navigator.pushScreen(FeathersSDKManager.SCREEN_ID_INSTALL_PROGRESS);
		}
		
		private function context_acquireBinaryDistributionErrorHandler(event:starling.events.Event, errorMessage:String):void
		{
			var item:StackScreenNavigatorItem = this.navigator.installError;
			item.properties.errorMessage = errorMessage;
			this.navigator.pushScreen(FeathersSDKManager.SCREEN_ID_INSTALL_ERROR);
		}
		
		private function context_acquireBinaryDistributionCompleteHandler(event:starling.events.Event):void
		{
			this.installerService.runInstallerScript();
		}
		
		private function context_runInstallerScriptStartHandler(event:starling.events.Event):void
		{
			this.navigator.pushScreen(FeathersSDKManager.SCREEN_ID_INSTALL_PROGRESS);
		}
		
		private function context_runInstallerScriptErrorHandler(event:starling.events.Event, errorMessage:String):void
		{
			var item:StackScreenNavigatorItem = this.navigator.installError;
			item.properties.errorMessage = errorMessage;
			this.navigator.pushScreen(FeathersSDKManager.SCREEN_ID_INSTALL_ERROR);
		}
		
		private function context_runInstallerScriptCompleteHandler(event:starling.events.Event):void
		{
			this.navigator.pushScreen(FeathersSDKManager.SCREEN_ID_INSTALL_COMPLETE);
		}
		
		private function downloadCacheMenuItem_menuItemSelectHandler(event:ContextMenuEvent):void
		{
			var menuItem:ContextMenuItem = ContextMenuItem(event.currentTarget);
			this.navigator.pushScreen(FeathersSDKManager.SCREEN_ID_DOWNLOAD_CACHE);
		}
	}
}