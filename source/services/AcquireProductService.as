/*
Feathers SDK Installer
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

	import model.InstallerModel;
	import model.ProductConfigurationItem;

	import org.as3commons.zip.Zip;
	import org.as3commons.zip.ZipEvent;
	import org.as3commons.zip.ZipFile;
	import org.robotlegs.starling.mvcs.Actor;

	public class AcquireProductService extends Actor implements IAcquireProductService
	{	
		private static const ACQUISITION_IN_PROGRESS_ERROR:String = "Downloading the Feathers SDK failed. A download is already in progress.";
		private static const NO_PRODUCT_SELECTED_ERROR:String = "Downloading the Feathers SDK failed. No version of the Feathers SDK is selected.";
		private static const NOT_FOUND_ON_SERVER_ERROR:String = "Downloading the Feathers SDK failed. The binary distribution was not found on the server.";
		private static const BINARY_DISTRIBUTION_NOT_FOUND_ERROR:String = "Downloading the Feathers SDK failed. Downloaded file not found.";
		
		private static const LOAD_PROGRESS_LABEL:String = "Downloading Feathers SDK...";
		private static const DECOMPRESS_PROGRESS_LABEL:String = "Decompressing Feathers SDK...";
		
		[Inject]
		public var installerModel:InstallerModel;
		
		private var _process:NativeProcess;
		private var _tempDirectory:File;
		private var _unzipDirectory:File;
		private var _fileUnzipErrorFunction:Function;
		private var _loader:URLLoader;
		
		public function get isActive():Boolean
		{
			return this._tempDirectory !== null;
		}
		
		public function acquireSelectedProduct():void
		{
			this.dispatchWith(AcquireProductServiceEventType.START);
			
			if(this.isActive)
			{
				this.dispatchWith(AcquireProductServiceEventType.ERROR, false, ACQUISITION_IN_PROGRESS_ERROR);
				return;
			}
			
			if(this.installerModel.selectedProduct === null)
			{
				this.dispatchWith(AcquireProductServiceEventType.ERROR, false, NO_PRODUCT_SELECTED_ERROR);
				return;
			}
			
			this._tempDirectory = File.createTempDirectory();
			
			if(this.installerModel.downloadCacheEnabled)
			{
				var cacheFile:File = this.getProductCacheFile();
				//we can skip downloading this file because it's already
				//in the cache.
				if(cacheFile.exists)
				{
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
			this._loader = new URLLoader();
			this._loader.dataFormat = URLLoaderDataFormat.BINARY;
			this._loader.addEventListener(Event.COMPLETE, loader_completeHandler);
			this._loader.addEventListener(ProgressEvent.PROGRESS, loader_progressHandler);
			this._loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			this._loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			this._loader.load(new URLRequest(url));
		}
		
		private function getProductFileName():String
		{
			var selectedProduct:ProductConfigurationItem = this.installerModel.selectedProduct;
			var extension:String = ".tar.gz";
			if(this.installerModel.operatingSystem == InstallerModel.OPERATING_SYSTEM_WINDOWS)
			{
				extension = ".zip";
			}
			return selectedProduct.file + extension;
		}
		
		private function getProductURL():String
		{
			var selectedProduct:ProductConfigurationItem = this.installerModel.selectedProduct;
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
			return this.installerModel.downloadCacheDirectory.resolvePath(escape(url));
		}
		
		private function saveProductFile(bytes:ByteArray):void
		{	
			var selectedProduct:ProductConfigurationItem = this.installerModel.selectedProduct;
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
			
			if(!this.installerModel.downloadCacheEnabled)
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
			var selectedProduct:ProductConfigurationItem = this.installerModel.selectedProduct;
			var binaryDistribution:File = this._tempDirectory.resolvePath(this.getProductFileName());
			if(!binaryDistribution.exists)
			{
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, BINARY_DISTRIBUTION_NOT_FOUND_ERROR);
				this.cleanup();
				return;
			}
			if(this.installerModel.operatingSystem == InstallerModel.OPERATING_SYSTEM_WINDOWS) //zip
			{
				this._unzipDirectory = this._tempDirectory.resolvePath(selectedProduct.file);
				this._unzipDirectory.createDirectory();
				unzip(binaryDistribution, unzip_completeHandler, unzip_errorHandler);
			}
			else //Mac and tar.gz
			{
				this._unzipDirectory = this._tempDirectory.resolvePath(selectedProduct.file);
				untar(binaryDistribution, this._tempDirectory, unzip_completeHandler, unzip_errorHandler);
			}
		}
		
		private function cleanup():void
		{
			if(this._loader)
			{
				this._loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
				this._loader.removeEventListener(ProgressEvent.PROGRESS, loader_progressHandler);
				this._loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
				this._loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
				this._loader = null;
			}
			this._unzipDirectory = null;
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
						trace("Installer error: cannot delete temporary directory.");
					}
				}
				this._tempDirectory = null;
			}
		}
		
		private function unzip(fileToUnzip:File, unzipCompleteFunction:Function, unzipErrorFunction:Function = null):void
		{
			var zipFileBytes:ByteArray = new ByteArray();
			var fs:FileStream = new FileStream();
			var fzip:Zip = new Zip();
			
			fs.open(fileToUnzip, FileMode.READ);
			fs.readBytes(zipFileBytes);
			fs.close();
			
			fzip.addEventListener(ZipEvent.FILE_LOADED, onFileLoaded, false, 0, true);
			fzip.addEventListener(Event.COMPLETE, unzipCompleteFunction, false, 0, true);
			fzip.addEventListener(Event.COMPLETE, onUnzipComplete, false, 0, true);
			if (unzipErrorFunction != null)
			{
				fzip.addEventListener(ErrorEvent.ERROR, unzipErrorFunction, false, 0, true);
				_fileUnzipErrorFunction = unzipErrorFunction
			}
			fzip.loadBytes(zipFileBytes);
		}
		
		private function onFileLoaded(e:ZipEvent):void
		{
			try
			{
				var fzf:ZipFile = e.file;
				var f:File = this._unzipDirectory.resolvePath(fzf.filename);
				var fs:FileStream = new FileStream();
				
				if (isZipFileADirectory(fzf))
				{
					// Is a directory, not a file. Dont try to write anything into it.
					return;
				}
				
				fs.open(f, FileMode.WRITE);
				fs.writeBytes(fzf.content);
				fs.close();
				
			}
			catch (error:Error)
			{
				_fileUnzipErrorFunction.call();
			}
		}
		
		private function onUnzipComplete(event:Event):void
		{
			var fzip:Zip = event.target as Zip;
			fzip.close();
			fzip.removeEventListener(ZipEvent.FILE_LOADED, onFileLoaded);
			fzip.removeEventListener(Event.COMPLETE, onUnzipComplete);
		}
		
		private function isZipFileADirectory(f:ZipFile):Boolean
		{
			if (f.filename.substr(f.filename.length - 1) == "/" || f.filename.substr(f.filename.length - 1) == "\\")
			{
				return true;
			}
			return false;
		}
		
		private function untar(source:File, destination:File, unTarCompleteCallback:Function, unTarErrorCallback:Function):void
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
			this._process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, unTarErrorCallback, false, 0, true);
			this._process.addEventListener(NativeProcessExitEvent.EXIT, unTarCompleteCallback, false, 0, true);
			this._process.addEventListener(NativeProcessExitEvent.EXIT, untar_completeHandler, false, 0, true);
			this._process.start(startupInfo);
			this.dispatchWith(AcquireProductServiceEventType.PROGRESS, false, new ProgressEventData(1, DECOMPRESS_PROGRESS_LABEL));
		}
		
		private function untar_completeHandler(event:NativeProcessExitEvent):void
		{
			this._process.closeInput();
			this._process.exit(true);
			this._process = null;
		}
		
		private function unzip_completeHandler(event:Event):void
		{
			if(!this._unzipDirectory.exists || !this._unzipDirectory.isDirectory)
			{
				this.cleanup();
				this.dispatchWith(RunInstallScriptServiceEventType.ERROR, false, BINARY_DISTRIBUTION_NOT_FOUND_ERROR);
				return;
			}
			var installDirectory:File = this.installerModel.installDirectory;
			var files:Array = this._unzipDirectory.getDirectoryListing();
			for each(var file:File in files)
			{
				file.copyTo(installDirectory.resolvePath(file.name));
			}
			this.cleanup();
			this.dispatchWith(AcquireProductServiceEventType.COMPLETE);
		}
		
		private function unzip_errorHandler(event:Event):void
		{
			this._process = null;
			this.cleanup();
			this.dispatchWith(AcquireProductServiceEventType.ERROR, false);
		}
		
		private function loader_completeHandler(event:Event):void
		{
			this.saveProductFile(this._loader.data as ByteArray);
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
			this.dispatchWith(AcquireProductServiceEventType.ERROR, false, NOT_FOUND_ON_SERVER_ERROR);
		}
		
		private function loader_securityErrorHandler(event:SecurityErrorEvent):void
		{
			this.cleanup();
			this.dispatchWith(AcquireProductServiceEventType.ERROR, false, NOT_FOUND_ON_SERVER_ERROR);
		}
	}
}