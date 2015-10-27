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
	import events.AcquireProductServiceEventType;
	import events.ProgressEventData;
	import events.RunInstallScriptServiceEventType;

	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;

	import model.SDKManagerModel;
	import model.ProductConfigurationItem;

	import org.as3commons.zip.Zip;
	import org.as3commons.zip.ZipEvent;
	import org.as3commons.zip.ZipFile;
	import org.robotlegs.starling.mvcs.Actor;

	import starling.events.Event;

	public class AcquireProductService extends Actor implements IAcquireProductService
	{	
		private static const ACQUISITION_IN_PROGRESS_ERROR:String = "Downloading the Feathers SDK failed. A download is already in progress.";
		private static const NO_PRODUCT_SELECTED_ERROR:String = "Downloading the Feathers SDK failed. No version of the Feathers SDK is selected.";
		private static const NOT_FOUND_ON_SERVER_ERROR:String = "Downloading the Feathers SDK failed. The binary distribution was not found on the server.";
		private static const SECURITY_ERROR:String = "Downloading the Feathers SDK failed. Security sandbox error.";
		private static const BINARY_DISTRIBUTION_NOT_FOUND_ERROR:String = "Downloading the Feathers SDK failed. Downloaded file not found.";
		private static const DECOMPRESS_ERROR:String = "Decompressing the Feathers SDK failed.";
		private static const COPY_ERROR:String = "Copying the Feathers SDK to destination directory failed.";
		
		private static const LOAD_PROGRESS_LABEL:String = "Downloading Feathers SDK...";
		private static const DECOMPRESS_PROGRESS_LABEL:String = "Decompressing Feathers SDK...";
		
		[Inject]
		public var sdkManagerModel:SDKManagerModel;
		
		private var _tempDirectory:File;
		private var _destinationDirectory:File;
		private var _loader:URLLoader;
		private var _zip:Zip;
		private var _process:NativeProcess;
		
		public function get isActive():Boolean
		{
			return this._tempDirectory !== null;
		}
		
		public function acquireSelectedProduct():void
		{
			this.dispatchWith(AcquireProductServiceEventType.START);
			
			if(this.isActive)
			{
				this.sdkManagerModel.log(ACQUISITION_IN_PROGRESS_ERROR);
				this.dispatchWith(AcquireProductServiceEventType.ERROR, false, ACQUISITION_IN_PROGRESS_ERROR);
				return;
			}
			
			if(this.sdkManagerModel.selectedProduct === null)
			{
				this.sdkManagerModel.log(NO_PRODUCT_SELECTED_ERROR);
				this.dispatchWith(AcquireProductServiceEventType.ERROR, false, NO_PRODUCT_SELECTED_ERROR);
				return;
			}
			
			this.eventDispatcher.addEventListener(AcquireProductServiceEventType.CANCEL, context_aquireProductCancelHandler);
			
			this._tempDirectory = File.createTempDirectory();
			
			if(this.sdkManagerModel.downloadCacheEnabled)
			{
				var cacheFile:File = this.getProductCacheFile();
				//we can skip downloading this file because it's already
				//in the cache.
				if(cacheFile.exists)
				{
					this.sdkManagerModel.log("Loading product from download cache: " + this.getProductFileName());
					var bytes:ByteArray = new ByteArray();
					var stream:FileStream = new FileStream();
					stream.open(cacheFile, FileMode.READ);
					stream.readBytes(bytes);
					stream.close();
					this.saveProductFile(bytes);
					this.decompress();
					return;
				}
			}
			var url:String = this.getProductURL();
			this.sdkManagerModel.log("Loading product from URL: " + url);
			this._loader = new URLLoader();
			this._loader.dataFormat = URLLoaderDataFormat.BINARY;
			this._loader.addEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
			this._loader.addEventListener(ProgressEvent.PROGRESS, loader_progressHandler);
			this._loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			this._loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			this._loader.load(new URLRequest(url));
		}
		
		private function getProductFileName():String
		{
			var selectedProduct:ProductConfigurationItem = this.sdkManagerModel.selectedProduct;
			var extension:String = ".tar.gz";
			if(this.sdkManagerModel.operatingSystem == SDKManagerModel.OPERATING_SYSTEM_WINDOWS)
			{
				extension = ".zip";
			}
			return selectedProduct.file + extension;
		}
		
		private function getProductURL():String
		{
			var selectedProduct:ProductConfigurationItem = this.sdkManagerModel.selectedProduct;
			return selectedProduct.path + this.getProductFileName();
		}
		
		private function getProductCacheFile():File
		{
			var url:String = this.getProductURL();
			var c:int = url.indexOf("/");
			c = url.indexOf("/", c + 1);
			c = url.indexOf("/", c + 1);
			// that should find the slash after the server.
			url = url.substr(c + 1);
			return this.sdkManagerModel.downloadCacheDirectory.resolvePath(escape(url));
		}
		
		private function saveProductFile(bytes:ByteArray):void
		{	
			var binaryDistribution:File = this._tempDirectory.resolvePath(this.getProductFileName());
			if(binaryDistribution.exists)
			{
				//replace the old file
				binaryDistribution.deleteFile();
			}
			var stream:FileStream = new FileStream();
			stream.open(binaryDistribution, FileMode.WRITE);
			stream.writeBytes(bytes);
			stream.close();
			
			if(!this.sdkManagerModel.downloadCacheEnabled)
			{
				return;
			}
			
			var cacheFile:File = this.getProductCacheFile();
			//only save if the file doesn't already exist. if it exists, then
			//the data already came from the cache.
			if(!cacheFile.exists)
			{
				binaryDistribution.copyTo(cacheFile);
			}
		}
			
		private function decompress():void
		{
			var selectedProduct:ProductConfigurationItem = this.sdkManagerModel.selectedProduct;
			var binaryDistribution:File = this._tempDirectory.resolvePath(this.getProductFileName());
			if(!binaryDistribution.exists)
			{
				this.sdkManagerModel.log(BINARY_DISTRIBUTION_NOT_FOUND_ERROR);
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, BINARY_DISTRIBUTION_NOT_FOUND_ERROR);
				this.cleanup();
				return;
			}
			this.sdkManagerModel.log("Decompressing product.");
			if(this.sdkManagerModel.operatingSystem == SDKManagerModel.OPERATING_SYSTEM_WINDOWS) //zip
			{
				this._destinationDirectory = this._tempDirectory.resolvePath(selectedProduct.file);
				this._destinationDirectory.createDirectory();
				this.unzip(binaryDistribution);
			}
			else //Mac and tar.gz
			{
				this._destinationDirectory = this._tempDirectory.resolvePath(selectedProduct.file);
				this.untar(binaryDistribution, this._tempDirectory);
			}
		}
		
		private function cleanup():void
		{
			this.eventDispatcher.removeEventListener(AcquireProductServiceEventType.CANCEL, context_aquireProductCancelHandler);
			if(this._loader)
			{
				this._loader.removeEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
				this._loader.removeEventListener(ProgressEvent.PROGRESS, loader_progressHandler);
				this._loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
				this._loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
				this._loader = null;
			}
			if(this._zip)
			{
				this._zip.close();
				this._zip.removeEventListener(ZipEvent.FILE_LOADED, onFileLoaded);
				this._zip.removeEventListener(flash.events.Event.COMPLETE, decompress_completeHandler);
				this._zip.removeEventListener(ErrorEvent.ERROR, decompress_errorHandler);
				this._zip = null;
			}
			if(this._process)
			{
				this._process.closeInput();
				this._process.exit(true);
				this._process = null;
			}
			this._destinationDirectory = null;
			if(this._tempDirectory)
			{
				if(this._tempDirectory.isDirectory && this._tempDirectory.exists)
				{
					try
					{
						this._tempDirectory.deleteDirectory(true);
					} 
					catch(error:Error) 
					{
						//this is a non-fatal error, so we'll just log it.
						this.sdkManagerModel.log("Error while deleting temporary directory.");
					}
				}
				this._tempDirectory = null;
			}
		}
		
		private function unzip(fileToUnzip:File):void
		{
			var zipFileBytes:ByteArray = new ByteArray();
			var fs:FileStream = new FileStream();
			this._zip = new Zip();
			
			fs.open(fileToUnzip, FileMode.READ);
			fs.readBytes(zipFileBytes);
			fs.close();
			
			this._zip.addEventListener(ZipEvent.FILE_LOADED, onFileLoaded, false, 0, true);
			this._zip.addEventListener(flash.events.Event.COMPLETE, decompress_completeHandler, false, 0, true);
			this._zip.addEventListener(ErrorEvent.ERROR, decompress_errorHandler, false, 0, true);
			this._zip.loadBytes(zipFileBytes);
		}
		
		private function onFileLoaded(e:ZipEvent):void
		{
			try
			{
				var fzf:ZipFile = e.file;
				var f:File = this._destinationDirectory.resolvePath(fzf.filename);
				
				if (isZipFileADirectory(fzf))
				{
					//the directory may be empty, but we still want to keep it
					//because certain IDEs expect specific directories to exist
					//no matter what
					f.createDirectory();
					return;
				}

				var fs:FileStream = new FileStream();
				fs.open(f, FileMode.WRITE);
				fs.writeBytes(fzf.content);
				fs.close();
			}
			catch (error:Error)
			{
				this.cleanup();
				this.sdkManagerModel.log(DECOMPRESS_ERROR);
				this.dispatchWith(AcquireProductServiceEventType.ERROR, false, DECOMPRESS_ERROR);
			}
		}
		
		private function isZipFileADirectory(f:ZipFile):Boolean
		{
			if(f.filename.substr(f.filename.length - 1) == "/" || f.filename.substr(f.filename.length - 1) == "\\")
			{
				return true;
			}
			return false;
		}
		
		private function untar(source:File, destination:File):void
		{
			var tar:File;
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var arguments:Vector.<String> = new Vector.<String>();
			
			if(Capabilities.os.toLowerCase().indexOf("mac") === 0)
			{
				tar = new File("/usr/bin/tar");
			}
			else
			{
				tar = new File("/bin/tar");
			}
			
			arguments.push("xf");
			arguments.push(source.nativePath);
			arguments.push("-C");
			arguments.push(destination.nativePath);
			
			startupInfo.executable = tar;
			startupInfo.arguments = arguments;
			
			this._process = new NativeProcess();
			this._process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, decompress_errorHandler, false, 0, true);
			this._process.addEventListener(NativeProcessExitEvent.EXIT, decompress_completeHandler, false, 0, true);
			this._process.start(startupInfo);
			this.dispatchWith(AcquireProductServiceEventType.PROGRESS, false, new ProgressEventData(1, DECOMPRESS_PROGRESS_LABEL));
		}
		
		private function decompress_completeHandler(event:flash.events.Event):void
		{
			if(!this._destinationDirectory.exists || !this._destinationDirectory.isDirectory)
			{
				this.cleanup();
				this.sdkManagerModel.log(BINARY_DISTRIBUTION_NOT_FOUND_ERROR);
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, BINARY_DISTRIBUTION_NOT_FOUND_ERROR);
				return;
			}
			this.sdkManagerModel.log("Product decompressed successfully.");
			var installDirectory:File = this.sdkManagerModel.installDirectory;
			this.sdkManagerModel.log("Copying files to destination: " + installDirectory.nativePath);
			try
			{
				var files:Array = this._destinationDirectory.getDirectoryListing();
				for each(var file:File in files)
				{
					file.copyTo(installDirectory.resolvePath(file.name));
				}
			}
			catch(error:Error)
			{
				this.cleanup();
				this.sdkManagerModel.log(COPY_ERROR + " " + error);
				this.dispatchWith(AcquireProductServiceEventType.ERROR, false, COPY_ERROR);
				return;
			}
			this.sdkManagerModel.log("Files copied successfully.");
			this.cleanup();
			this.dispatchWith(AcquireProductServiceEventType.COMPLETE);
		}
		
		private function decompress_errorHandler(event:flash.events.Event):void
		{
			this.cleanup();
			this.sdkManagerModel.log(DECOMPRESS_ERROR);
			this.dispatchWith(AcquireProductServiceEventType.ERROR, false, DECOMPRESS_ERROR);
		}
		
		private function loader_completeHandler(event:flash.events.Event):void
		{
			var productData:ByteArray = this._loader.data as ByteArray;
			this.sdkManagerModel.log("Product loaded successfully. " + productData.length + " bytes.");
			this.saveProductFile(productData);
			this.decompress();
		}
		
		private function loader_progressHandler(event:ProgressEvent):void
		{
			var progress:Number = event.bytesLoaded / event.bytesTotal;
			this.dispatchWith(AcquireProductServiceEventType.PROGRESS, false, new ProgressEventData(progress, LOAD_PROGRESS_LABEL));
		}
		
		private function loader_ioErrorHandler(event:IOErrorEvent):void
		{
			this.cleanup();
			this.sdkManagerModel.log(NOT_FOUND_ON_SERVER_ERROR + " " + event);
			this.dispatchWith(AcquireProductServiceEventType.ERROR, false, NOT_FOUND_ON_SERVER_ERROR);
		}
		
		private function loader_securityErrorHandler(event:SecurityErrorEvent):void
		{
			this.cleanup();
			this.sdkManagerModel.log(SECURITY_ERROR + " " + event);
			this.dispatchWith(AcquireProductServiceEventType.ERROR, false, SECURITY_ERROR);
		}
		
		private function context_aquireProductCancelHandler(event:starling.events.Event):void
		{
			if(this._loader)
			{
				this._loader.close();
			}
			this.cleanup();
		}
		
	}
}