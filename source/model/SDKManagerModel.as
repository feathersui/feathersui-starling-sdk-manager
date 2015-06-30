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
package model
{
	import flash.filesystem.File;
	import flash.system.Capabilities;

	public class SDKManagerModel
	{
		private static const FEATHERS_SDK_LICENSE_NAME:String = "Feathers SDK";
		private static const AIR_SDK_LICENSE_NAME:String = "Adobe AIR SDK";
		private static const PLAYERGLOBAL_LICENSE_NAME:String = "Adobe Flash Player playerglobal.swc";
		private static const FLEX_SDK_FONTS_LICENSE_NAME:String = "Adobe Embedded Font Libraries and Utilities";
		private static const APACHE_LICENSE_URL:String = "http://www.apache.org/licenses/LICENSE-2.0.html";
		private static const AIR_SDK_LICENSE_URL:String = "http://www.adobe.com/products/air/sdk-eula.html";
		private static const FLEX_SDK_LICENSE_URL:String = "http://www.adobe.com/products/eulas/pdfs/adobe_flex_software_development_kit-combined-20110916_0930.pdf";
		
		public static const OPERATING_SYSTEM_WINDOWS:String = "windows";
		public static const OPERATING_SYSTEM_MAC:String = "mac";
		
		public var installDirectory:File;
		public var selectedProduct:ProductConfigurationItem;
		public var selectedRuntime:RuntimeConfigurationItem;
		public var downloadCacheEnabled:Boolean = false;
		public var downloadCacheDirectory:File = File.applicationStorageDirectory.resolvePath("feathers_sdk_download_cache");
		
		private var _licenses:Vector.<LicenseItem> = new <LicenseItem>
		[
			new LicenseItem(FEATHERS_SDK_LICENSE_NAME, APACHE_LICENSE_URL),
			new LicenseItem(AIR_SDK_LICENSE_NAME, AIR_SDK_LICENSE_URL),
			new LicenseItem(PLAYERGLOBAL_LICENSE_NAME, FLEX_SDK_LICENSE_URL),
			new LicenseItem(FLEX_SDK_FONTS_LICENSE_NAME, FLEX_SDK_LICENSE_URL),
		];

		public function get licenses():Vector.<LicenseItem>
		{
			return this._licenses;
		}
		
		private var _runtimes:Vector.<RuntimeConfigurationItem>;
		
		public function get runtimes():Vector.<RuntimeConfigurationItem>
		{
			return this._runtimes;
		}
		
		private var _products:Vector.<ProductConfigurationItem>;
		
		public function get products():Vector.<ProductConfigurationItem>
		{
			return this._products;
		}
		
		private var _operatingSystem:String;
		
		public function get operatingSystem():String
		{
			if(this._operatingSystem === null)
			{
				if(Capabilities.os.indexOf("Mac OS") >= 0)
				{
					this._operatingSystem = OPERATING_SYSTEM_MAC;
				}
				else
				{
					this._operatingSystem = OPERATING_SYSTEM_WINDOWS;
				}
			}
			return this._operatingSystem;
		}
		
		public function parseConfiguration(data:XML):void
		{
			try
			{
				this.parseProducts(data);
				this.parseRuntimes(data);
			} 
			catch(error:Error) 
			{
				//something didn't parse correctly, so we don't want any broken
				//data to be displayed.
				this._products = null;
				this._runtimes = null;
			}
		}
		
		private function parseProducts(data:XML):void
		{
			var products:Vector.<ProductConfigurationItem> = new <ProductConfigurationItem>[];
			
			var productData:XMLList = data.products;
			var productsList:XMLList = data.products[0].children();
			var productCount:int = productsList.length();
			for(var i:int = 0; i < productCount; i++)
			{
				var product:XML = productsList[i] as XML;
				this.parseProduct(product, products);
			}
			
			this._products = products.reverse();
		}
		
		private function parseProduct(data:XML, result:Vector.<ProductConfigurationItem>):void
		{
			var productName:String = data.@name.toString();
			var productData:XMLList = data.versions;
			var versionList:XMLList = productData[0].children();
			var defaultVersionNumber:String = productData[0]["@default"].toString();
			var versionCount:int = versionList.length(); 
			for(var i:int = 0; i < versionCount; i++)
			{
				var version:XML = versionList[i] as XML;
				var displayVersion:String = version.@displayVersion.toString();
				var versionNumber:String = version.@version.toString();
				var versionID:String = null;
				if(version.@versionID.length() > 0)
				{
					versionID = version.@versionID.toString();
				}
				var path:String = version.path.toString();
				var file:String = version.file.toString();
				
				var item:ProductConfigurationItem = new ProductConfigurationItem();
				item.label = productName + " " + displayVersion;
				item.versionNumber = versionNumber;
				item.versionID = versionID;
				item.path = path;
				item.file = file;
				result.push(item);
				
				if(versionNumber === defaultVersionNumber)
				{
					this.selectedProduct = item;
				}
			}
		}
		
		private function parseRuntimes(data:XML):void
		{
			var runtimes:Vector.<RuntimeConfigurationItem> = new <RuntimeConfigurationItem>[];
			
			var playerGlobalData:XMLList = data.flashsdk.versions;
			var airData:XMLList = data.airsdk[this.operatingSystem].versions;
			var playerGlobalVersionList:XMLList = playerGlobalData[0].children();
			var airVersionList:XMLList = airData[0].children();
			if(playerGlobalVersionList.length() != airVersionList.length())
			{
				throw new SyntaxError("AIR version count must match Flash Player version count.");
			}
			var defaultAIRVersionNumber:String = airData[0]["@default"].toString();
			var versionCount:int = airVersionList.length(); 
			for(var i:int = 0; i < versionCount; i++)
			{
				var airVersion:XML = airVersionList[i] as XML;
				var airDisplayVersion:String = airVersion.@displayVersion.toString();
				var airVersionNumber:String = airVersion.@version.toString();
				var airVersionID:String = null;
				if(airVersion.@versionID.length() > 0)
				{
					airVersionID = airVersion.@versionID.toString();
				}
				var airPath:String = airVersion.path.toString();
				var airFile:String = airVersion.file.toString();
				
				var playerGlobalVersion:XML = playerGlobalVersionList[i] as XML;
				var playerGlobalDisplayVersion:String = playerGlobalVersion.@displayVersion.toString();
				var playerGlobalVersionNumber:String = playerGlobalVersion.@version.toString();
				var playerGlobalVersionID:String = null;
				if(playerGlobalVersion.@versionID.length() > 0)
				{
					playerGlobalVersionID = playerGlobalVersion.@versionID.toString();
				}
				var playerGlobalPath:String = playerGlobalVersion.path.toString();
				var playerGlobalFile:String = playerGlobalVersion.file.toString();
				var swfVersion:String = playerGlobalVersion.swfversion.toString();
				
				var item:RuntimeConfigurationItem = new RuntimeConfigurationItem();
				item.label = "AIR " + airDisplayVersion + " and Flash Player " + playerGlobalDisplayVersion;
				item.airVersionNumber = airVersionNumber;
				item.airVersionID = airVersionID;
				item.airPath = airPath;
				item.airFile = airFile;
				item.playerGlobalVersionNumber = playerGlobalVersionNumber;
				item.playerGlobalVersionID = playerGlobalVersionID;
				item.playerGlobalPath = playerGlobalPath;
				item.playerGlobalFile = playerGlobalFile;
				item.swfVersion = swfVersion;
				runtimes.push(item);
				
				if(airVersionNumber === defaultAIRVersionNumber)
				{
					this.selectedRuntime = item;
				}
			}
			this._runtimes = runtimes.reverse();
		}
	}
}