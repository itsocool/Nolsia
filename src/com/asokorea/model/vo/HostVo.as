package com.asokorea.model.vo
{
	import flash.filesystem.File;
	import flash.utils.Dictionary;

	[Bindable]
	public class HostVo
	{
		public var no:uint;
		public var ip:String;
		public var hostName:String;
		public var user:String;
		public var password:String;
		public var port:int;
		public var canAccess:Boolean;
		public var isComplete:Boolean;
		public var isDefault:Boolean;
		public var userList:Dictionary;
		public var logFile:File;
		public var taskName:String;
		public var output:String;
	}
}
