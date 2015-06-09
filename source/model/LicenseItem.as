package model
{
	import starling.events.EventDispatcher;

	[Bindable]
	public class LicenseItem extends EventDispatcher
	{
		public function LicenseItem(name:String, url:String)
		{
			this.name = name;
			this.url = url;
		}
		
		public var name:String;
		public var url:String;
	}
}