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
		private var _taskBaseDir:File;
		private var _description:String;
		private var _importHostListFile:String;
		private var _exportedHostListFile:String;
		private var _logPath:String;
		private var _sshVo:SshVo;
		private var _configXmlPath:String;
		private var _configXml:XML;
		private var _hostListXml:XML;

		public var hostList:ArrayCollection;

		public function getHostVo(ip:String):HostVo
		{
			if(ip && hostList)
			{
				for each (var item:HostVo in hostList) 
				{
					if(item.ip == ip)
					{
						return item;
					}
				}
			}
			
			return null;
		}
		
		public function load(taskName:String = null):void
		{
			_taskName = taskName
			
			if(_taskName)
			{
				_taskBaseDir = Global.TASK_BASE_DIR.resolvePath(_taskName);
				
				if(!_taskBaseDir || !_taskBaseDir.exists || !_taskBaseDir.isDirectory)
				{
					var file:File = Global.TEMPLETE_DIR.resolvePath(Global.DEFAULT_TASK_NAME);
					file.copyTo(_taskBaseDir);
				}

				var configXmlFile:File = _taskBaseDir.resolvePath("config.xml");
				_configXmlPath = configXmlFile.nativePath;
				
				if(!configXmlFile || !configXmlFile.exists)
				{
					Global.TEMPLETE_DIR.resolvePath("task/" + Global.DEFAULT_TASK_NAME).resolvePath("config.xml").copyTo(configXmlFile);
				}
				
				configXml = Global.readXml(configXmlFile);
				
				if(_configXml)
				{
					_configXml.taskBaseDir = _taskBaseDir.nativePath;
				}
					
			}else{
				createNewTask(_taskName);
			}
		}
		
		public function createNewTask(taskName:String):Boolean
		{
			var result:Boolean;
			var templeteDir:File = Global.TEMPLETE_DIR.resolvePath("task/" + Global.DEFAULT_TASK_NAME);
			
			_taskBaseDir = File.userDirectory.resolvePath("task/" + taskName);
			
			if(templeteDir && templeteDir.exists && templeteDir.isDirectory)
			{
				templeteDir.copyTo(_taskBaseDir);
				
				if(_taskBaseDir && _taskBaseDir.exists && _taskBaseDir.isDirectory)
				{
					_taskName = taskName;
					_sshVo = new SshVo();
					save();
					result = true;
				}
			}
			
			return result
		}
		
		public function save():void
		{
			if(_taskName && _configXml && _taskBaseDir && _taskBaseDir.exists && _taskBaseDir.isDirectory)
			{
				var configXmlFile:File = _taskBaseDir.resolvePath("config.xml");
				
				_configXml.taskName = taskName;
				_configXml.description = Global.cdata(description, "description");
				
				if(_taskBaseDir.exists && _taskBaseDir.isDirectory)
				{
					_configXml.taskBaseDir = Global.cdata(_taskBaseDir.nativePath, "taskBaseDir");
				}else
				{
					_configXml.taskBaseDir = <taskBaseDir/>;
				}
				
				_configXml.importHostListFile = Global.cdata(importHostListFile, "importHostListFile");
				_configXml.exportedHostListFile = Global.cdata(exportedHostListFile, "exportedHostListFile");
				_configXml.logPath = Global.cdata(logPath, "logPath");
				
				_configXml.ssh.user = Global.cdata(sshVo.user, "user");
				_configXml.ssh.password = Global.cdata(sshVo.password, "password");
				_configXml.ssh.timeout = sshVo.timeout;
				_configXml.ssh.maxConnection = sshVo.maxConnection;
				_configXml.ssh.autoExit = sshVo.autoExit;
				_configXml.ssh.commands = <commands/>;
				
				for (var i:int = 0; i < sshVo.commands.length; i++) 
				{
					_configXml.ssh.commands.appendChild(Global.cdata(sshVo.commands[i], "command"));
				}
				
				Global.saveXml(_configXml, configXmlFile);
			}
		}
		
		protected function saveHostListXml(xml:XML):void
		{
			var file:File = null;
			var fileStream:FileStream = new FileStream();
			var data:String = xml.toString();
			
			try
			{
				file = _taskBaseDir.resolvePath("hostList.xml");
				data = data.replace(/\n/g, File.lineEnding);
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeUTFBytes(data); 
				fileStream.close();

				_exportedHostListFile = file.nativePath;
				_hostListXml = xml;
			} 
			catch(error:Error) 
			{
				if(fileStream)
				{
					fileStream.close();
				}
			}
		}
		
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
		
		public function get taskBaseDir():File
		{
			return _taskBaseDir;
		}
		
		protected function set taskBaseDir(value:File):void
		{
			
			_taskBaseDir = value;
		}
		
		public function get description():String
		{
			return _description;
		}
		
		public function set description(value:String):void
		{
			_description = value;
		}
		
		public function get importHostListFile():String
		{
			return _importHostListFile;
		}
		
		public function set importHostListFile(value:String):void
		{
			_importHostListFile = value;
		}
		
		public function get exportedHostListFile():String
		{
			return _exportedHostListFile;
		}
		
		public function set exportedHostListFile(value:String):void
		{
			_exportedHostListFile = value;
		}
		
		public function get logPath():String
		{
			return _logPath;
		}
		
		public function set logPath(value:String):void
		{
			_logPath = value;
		}
		
		public function get sshVo():SshVo
		{
			return _sshVo;
		}
		
		private function set sshVo(value:SshVo):void
		{
			_sshVo = value;
		}
		
		public function get configXmlPath():String
		{
			return _configXmlPath;
		}
		
//		private function get hostListXml():XML
//		{
//			return _hostListXml;
//		}
		
		public function set hostListXml(value:XML):void
		{
			var hostVo:HostVo = null;
			var list:ArrayCollection = null;
				
			if (value is XML)
			{
				list = new ArrayCollection();
				
				for (var i:int=0; i < value.sheet[0].row.length(); i++)
				{
					var row:Object= value.sheet[0].row[i];
					
					if(row && row.col && row.col[0].toString() && row.col[1].toString() && row.col[2].toString())
					{
						hostVo = new HostVo();
						hostVo.no = i + 1;
						hostVo.ip = row.col[0].toString();
						
						if(!hostVo.ip || hostVo.ip.search(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/) < 0)
						{
							continue;
						}
						
						hostVo.user = row.col[1].toString() || sshVo.user;
						hostVo.password = row.col[2].toString() || sshVo.password;
						hostVo.port ||= 22;
						hostVo.taskName = taskName;
						list.addItem(hostVo);
					}
				}
			}
			
			hostList = list;
			
			saveHostListXml(value);
			
			_hostListXml = value;
		}
		
		private function get configXml():XML
		{
			return _configXml;
		}
		
		private function set configXml(value:XML):void
		{
			_configXml = value;

			if(value)
			{
				_description = value.description;
				_importHostListFile = value.importHostListFile;
				_exportedHostListFile = value.exportedHostListFile;
				_logPath = value.logPath;

				var sshXml:XML = XML(value.ssh);
				
				_sshVo = new SshVo();
				sshVo.load(sshXml);
			}
		}		
//		
//		public function get hostList():ArrayCollection
//		{
//			return _hostList;
//		}
//		
//		private function set hostList(value:ArrayCollection):void
//		{
//			_hostList = value;
//		}
	}
}
