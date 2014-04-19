package com.asokorea.model.vo
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.xml.XMLDocument;

	[Bindable]
	public class TaskVo
	{
		public var taskName:String;
		public var description:String;
		public var importHostListFile:String;
		public var exportedHostListFile:String;
		public var logPath:String;
		public var ssh:SshVo;
		
		public function saveHostListXml(xml:XML):void
		{
			var file:File = File.userDirectory.resolvePath("task/" + taskName + "/hostList.xml");
			var fileStream:FileStream = new FileStream();
			var data:String = xml.toString();
			data = data.replace(/\n/g, File.lineEnding);
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(data); 
			fileStream.close();
			
			if(file && file.exists && file.size > 0)
			{
				exportedHostListFile = file.nativePath;
			}
		}
	}
}
