package com.asokorea.model.vo
{
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class HostVo
	{
		public var no:uint;
		public var hostName:String;
		public var label:String;
		public var loginId:String;
		public var password:String;
		public var port:int;
		public var commandFile:String;
		public var onLine:Boolean;
		public var configBackupOk:Boolean;
		public var isDefault:Boolean;
		public var userList:ArrayCollection;
		public var configFile:File;
		public var taskId:String;

		public function HostVo()
		{
		}
	}
}
