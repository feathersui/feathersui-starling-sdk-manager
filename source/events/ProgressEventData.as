package events
{
	public class ProgressEventData
	{
		public function ProgressEventData(progress:Number, label:String)
		{
			this.progress = progress;
			this.label = label;
		}
		
		public var progress:Number;
		public var label:String;
	}
}