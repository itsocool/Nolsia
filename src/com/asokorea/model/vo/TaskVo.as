package com.asokorea.model.vo
{
	import com.asokorea.util.Global;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.getClassByAlias;
	import flash.xml.XMLDocument;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class TaskVo
	{
		private var _taskName:String;
		public var description:String;
		public var importHostListFile:String;
		public var exportedHostListFile:String;
		public var logPath:String;
		public var ssh:SshVo;
		public var taskBaseDir:String;
		
		private var configXml:XML;
		private var hostListXml:XML;
		
		public function get taskName():String
		{
			return _taskName;
		}

		public function set taskName(value:String):void
		{
			if(value.match(/[^0-9a-zA-Z_-]/))
			{
				Error.throwError(TaskVo, 1);
			}
			
			_taskName = value;
		}

		public function loadTask(taskName:String = null):void
		{
			this.taskName = taskName
			
			if(taskName)
			{
				var taskBasePath:File = File.userDirectory.resolvePath("task/" + _taskName);
				
				if(taskBasePath && taskBasePath.exists && taskBasePath.isDirectory)
				{
					taskBaseDir = taskBasePath.nativePath;
				}
				
				var configXmlFile:File = File.userDirectory.resolvePath("task/" + _taskName + "/config.xml");
				configXml = Global.readXml(configXmlFile);
				
				description = configXml.description;
				importHostListFile = configXml.importHostListFile;
				exportedHostListFile = configXml.exportedHostListFile;
				logPath = configXml.logPath;
				
				var hostXmlFile:File = new File(configXml.importHostListFile);
				
				if(hostXmlFile && hostXmlFile.exists)
				{
					hostListXml = Global.readXml(hostXmlFile);
				}
				
				ssh = new SshVo();
				ssh.autoExit = configXml.ssh.autoExit;
				ssh.password = configXml.ssh.password;
				ssh.timeout = configXml.ssh.timeout;
				ssh.user = configXml.ssh.user;
				ssh.commands = new ArrayCollection();
				
				var commandList:XMLList = configXml..command;
				
				for each (var command:XML in commandList) 
				{
					ssh.commands.addItem(command.toString());
				}
			}
		}

		public function saveTask():void
		{
			if(taskName && configXml)
			{
				var configXmlFile:File = File.userDirectory.resolvePath("task/" + taskName + "/config.xml");
				
				configXml.taskName = taskName;
				configXml.description = Global.cdata(description, "description");
				configXml.importHostListFile = Global.cdata(importHostListFile, "importHostListFile");
				configXml.exportedHostListFile = Global.cdata(exportedHostListFile, "exportedHostListFile");
				configXml.logPath = Global.cdata(logPath, "logPath");
				
				configXml.ssh.user = Global.cdata(ssh.user, "user");
				configXml.ssh.password = Global.cdata(ssh.password, "password");
				configXml.ssh.timeout = ssh.timeout;
				configXml.ssh.autoExit = ssh.autoExit;
				configXml.ssh.commands = <commands/>;
				
				for (var i:int = 0; i < ssh.commands.length; i++) 
				{
					configXml.ssh.commands.appendChild(Global.cdata(ssh.commands[i], "command"));
				}
				
				Global.saveXml(configXml, configXmlFile);
			}
		}
		
		public function saveHostListXml(xml:XML):void
		{
			var file:File = null;
			var fileStream:FileStream = new FileStream();
			var data:String = xml.toString();
			
			try
			{
				file = File.userDirectory.resolvePath("task/" + taskName + "/hostList.xml");
				data = data.replace(/\n/g, File.lineEnding);
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeUTFBytes(data); 
				fileStream.close();
				
				exportedHostListFile = file.nativePath;
				hostListXml = xml;
			} 
			catch(error:Error) 
			{
				if(fileStream)
				{
					fileStream.close();
				}
			}
		}
	}
}
