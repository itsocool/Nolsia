package com.asokorea.event
{
	import flash.events.Event;
	import flash.filesystem.File;
	
	import mx.events.FileEvent;
	
	public class FileEventEX extends FileEvent
	{
		static public const HOSTLIST_FILE_BROWSE:String = "hostListFileBrowse";
		static public const HOSTLIST_FILE_LOAD:String = "hostListFileLoad";
		
		public function FileEventEX(type:String, file:File=null)
		{
			super(type, true, false, file);
		}
		
		override public function clone():Event
		{
			return new FileEventEX(this.type, this.file);
		}
	}
}