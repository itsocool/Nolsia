package com.asokorea.event
{
	import com.asokorea.model.vo.HostVo;
	
	import flash.events.Event;
	
	public class MultiSSHEvent extends Event
	{
		static public const START:String = "start";
		
		static public const CONNECTED:String = "connected";
		static public const COMPELETE:String = "compelete";
		static public const MESSAGE:String = "message";
		
		static public const LOGIN_FAIL:String = "loginFail";
		static public const TIMEOUT:String = "timeout";
		static public const SSH_ERROR:String = "sshError";
		static public const EXCEPTION:String = "exception";

		static public const FINISH:String = "finish";
		
		private var _data:String;
		private var _hostVo:HostVo;
		
		public function MultiSSHEvent(type:String, data:String = null, hostVo:HostVo = null)
		{
			super(type, true, true);
			_data = data;
			_hostVo = hostVo;
		}

		override public function clone():Event
		{
			return new MultiSSHEvent(type, _data, _hostVo);
		}
		
		public function get data():String
		{
			return _data;
		}
		
		public function get hostVo():HostVo
		{
			return _hostVo;
		}
	}
}