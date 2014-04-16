package com.asokorea.event
{
	import com.asokorea.model.vo.HostVo;
	
	import flash.events.Event;
	
	public class SSHEvent extends Event
	{
		static public const OUTPUT:String = "output";
		static public const ERROR:String = "error";
		
		private var _data:String;
		
		public function SSHEvent(type:String, data:String)
		{
			super(type, true, true);
			_data = data;
		}
		
		override public function clone():Event
		{
			return new SSHEvent(type, data);
		}
		
		public function get data():String
		{
			return _data;
		}

	}
}