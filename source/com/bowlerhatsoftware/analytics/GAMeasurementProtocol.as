/*
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
package com.bowlerhatsoftware.analytics
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	/**
	 * A simple implementation of the Google Analytics Measurement Protocol.
	 */
	public class GAMeasurementProtocol
	{
		/**
		 * @private
		 */
		internal static var loaders:Vector.<URLLoader> = new <URLLoader>[];

		/**
		 * @private
		 */
		private static var PRODUCTION_URL:String = "https://www.google-analytics.com/collect";

		/**
		 * @private
		 */
		private static var DEBUG_URL:String = "https://www.google-analytics.com/debug/collect";

		/**
		 * The Google Analytics tracking ID for your property. Has the following
		 * format: UA-XXXX-Y. Required.
		 */
		public static var trackingID:String;

		/**
		 * An anonymous client ID. Required.
		 */
		public static var clientID:String;

		/**
		 * The name of your application.
		 */
		public static var applicationName:String;

		/**
		 * The version of your application.
		 */
		public static var applicationVersion:String;

		/**
		 * When <code>true</code>, the data will be sent to the Google Analytics
		 * Measurement Protocol Validation Server. The result will be displayed
		 * in the console.
		 */
		public static var debugMode:Boolean = false;

		/**
		 * Tracks an event.
		 */
		public static function trackEvent(eventCategory:String, eventAction:String, eventLabel:String = null, eventValue:int = -1):void
		{
			var parameters:URLVariables = createURLVariablesWithDefaults();
			parameters.t = "event";
			parameters.ec = eventCategory;
			parameters.ea = eventAction;
			if(eventLabel !== null && eventLabel.length > 0)
			{
				parameters.el = eventLabel;
			}
			if(eventValue >= 0)
			{
				parameters.ev = eventValue.toString();
			}
			
			loadURLRequestWithParameters(parameters);
		}

		/**
		 * Tracks an exception.
		 */
		public static function trackException(exceptionDescription:String, isFatal:Boolean):void
		{
			var parameters:URLVariables = createURLVariablesWithDefaults();
			parameters.t = "exception";
			parameters.exd = exceptionDescription;
			parameters.exf = isFatal ? "1" : "0";

			loadURLRequestWithParameters(parameters);
		}

		/**
		 * @private
		 */
		private static function validateGlobalParameters():void
		{
			if(GAMeasurementProtocol.trackingID === null || GAMeasurementProtocol.trackingID.length === 0)
			{
				throw new ArgumentError("MeasurementProtocol.trackingID cannot be null.")
			}
			if(GAMeasurementProtocol.clientID === null || GAMeasurementProtocol.clientID.length === 0)
			{
				throw new ArgumentError("MeasurementProtocol.clientID cannot be null.")
			}
		}

		/**
		 * @private
		 */
		private static function createURLVariablesWithDefaults():URLVariables
		{
			validateGlobalParameters();
			var parameters:URLVariables = new URLVariables();
			parameters.v = "1";
			parameters.tid = trackingID;
			parameters.cid = clientID;
			if(applicationName !== null && applicationName.length > 0)
			{
				parameters.an = applicationName;
			}
			if(applicationVersion !== null && applicationVersion.length > 0)
			{
				parameters.av = applicationVersion;
			}
			return parameters;
		}

		/**
		 * @private
		 */
		private static function loadURLRequestWithParameters(parameters:URLVariables):void
		{
			var url:String = debugMode ? DEBUG_URL : PRODUCTION_URL;
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.POST;
			request.data = parameters;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, loader_completeHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			loaders[loaders.length] = loader;
			loader.load(request);
		}

		/**
		 * @private
		 */
		private static function cleanupLoader(loader:URLLoader):void
		{
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			var index:int = loaders.indexOf(loader);
			if(index === 0)
			{
				loaders.shift();
			}
			else if(index === loaders.length - 1)
			{
				loaders.pop();
			}
			else
			{
				loaders.splice(index, 1);
			}
		}

		/**
		 * @private
		 */
		private static function loader_completeHandler(event:Event):void
		{
			var loader:URLLoader = URLLoader(event.currentTarget);
			cleanupLoader(loader);
			if(debugMode)
			{
				trace(loader.data);
			}
		}

		/**
		 * @private
		 */
		private static function loader_ioErrorHandler(event:IOErrorEvent):void
		{
			var loader:URLLoader = URLLoader(event.currentTarget);
			cleanupLoader(loader);
			if(debugMode)
			{
				trace(event);
			}
		}

		/**
		 * @private
		 */
		private static function loader_securityErrorHandler(event:SecurityErrorEvent):void
		{
			var loader:URLLoader = URLLoader(event.currentTarget);
			cleanupLoader(loader);
			if(debugMode)
			{
				trace(event);
			}
		}
	}
}
