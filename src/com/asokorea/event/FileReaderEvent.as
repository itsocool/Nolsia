package com.asokorea.event
{
	import flash.events.Event;
	import flash.filesystem.File;
	
	import mx.events.FileEvent;

	public class FileReaderEvent extends FileEvent
	{
		public static const READ_FILE_LIST:String="readFileList";
		public static const FILE_FILTERING:String="fileFiltering";
		public static const FILE_EXPORT:String="fileExport";
		public static const HOSTLIST_SELECT:String="hostListSelect";

		public function FileReaderEvent(type:String, file:File=null)
		{
			super(type, true, true, file);
		}

		override public function clone():Event
		{
			return new FileReaderEvent(this.type, this.file);
		}
	}
}
