package commands
{
	import flash.net.SharedObject;

	import mx.utils.UIDUtil;

	import com.bowlerhatsoftware.analytics.GAMeasurementProtocol;
	import org.robotlegs.starling.mvcs.Command;

	public class AnalyticsInitCommand extends Command
	{
		[Inject(name="applicationVersion")]
		public var applicationVersion:String;
		
		override public function execute():void
		{
			GAMeasurementProtocol.debugMode = false;
			GAMeasurementProtocol.trackingID = CONFIG::ANALYTICS_TRACKING_ID;
			GAMeasurementProtocol.clientID = getUID();
			GAMeasurementProtocol.applicationName = "Feathers SDK Manager";
			GAMeasurementProtocol.applicationVersion = applicationVersion;
		}
		
		private function getUID():String
		{
			var so:SharedObject = SharedObject.getLocal("uid");
			var uid:String = so.data.uid;
			if(uid === null)
			{
				so.data.uid = uid = UIDUtil.createUID();
				so.flush();
			}
			return uid;
		}
	}
}
