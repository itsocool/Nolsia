package com.asokorea.event
{
	import com.asokorea.model.vo.HostVo;
	
	import flash.events.Event;
	
	public class HostEvent extends Event
	{
		public static const SET_DEFAULT:String = "setDefault";
		public static const ADD:String = "add";
		public static const OPEN:String = "open";
		public static const EDIT:String = "edit";
		public static const DELETE:String = "delete";
		public static const EXECUTE:String = "execute";
		public static const STOP:String = "stop";
		
		private var _host:HostVo;
		
		public function HostEvent(type:String, host:HostVo = null)
		{
			super(type, true, true);
			_host = host;			
		}
		
		override public function clone():Event
		{
			return new HostEvent(type, _host);
		}

		public function get hostVo():HostVo
		{
			return _host;
		}
	}
}