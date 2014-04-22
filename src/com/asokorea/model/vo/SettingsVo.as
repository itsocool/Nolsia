package com.asokorea.model.vo
{
	import com.asokorea.util.Global;
	
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class SettingsVo
	{
		public var defaultTask:String = "_default_";
		public var tasks:ArrayCollection;
		public var defaultLogDir:File = File.userDirectory.resolvePath("logs");
		
		public static var SETTING_FILE:File = File.userDirectory.resolvePath("task/settings.xml");
		public static var DEFAULT_LOG_DIR:File = File.userDirectory.resolvePath("logs");
		
		private var settingXml:XML = null;
		
		public function SettingsVo()
		{
			if(!SETTING_FILE.exists)
			{
				var file:File = File.applicationDirectory.resolvePath("templete/task");
				file.copyTo(File.userDirectory.resolvePath("task"));
				SETTING_FILE = File.userDirectory.resolvePath("task/settings.xml");
			}
			
			settingXml = Global.readXml(SETTING_FILE); 
//			settingXml..taskBaseDir[0] = Global.cdata(file.resolvePath("_default_").nativePath);
			
			if(settingXml is XML && settingXml..taskRef is XMLList)
			{
				var taskList:XMLList = settingXml..taskRef as XMLList;
				tasks = new ArrayCollection();
		
				for each (var taskRef:XML in taskList) 
				{
					var taskName:String = taskRef.taskName.toString();
					var taskBaseDir:String = taskRef.taskBaseDir.toString();
					var taskVo:TaskVo = new TaskVo();
					
					taskVo.taskName = taskName;
					taskVo.loadTask(taskName);
					tasks.addItem(taskVo);
					taskRef.taskBaseDir = Global.cdata(taskVo.taskBaseDir, "taskBaseDir");
				}
			}
			
			var logDir:File = null;
			var dir:String = settingXml.defaultLogDir;
			
			if(dir)
			{
				logDir = new File(dir);
			}else
			{
				logDir = File.userDirectory.resolvePath("logs");
			}
			
			if(logDir.exists && logDir.isDirectory)
			{
				defaultLogDir = logDir;
			}else
			{
				if(!defaultLogDir.exists)
				{
					defaultLogDir.createDirectory();
				}
			}
			
			settingXml.defaultLogDir = Global.cdata(logDir.nativePath, "defaultLogDir");
			save();
		}
		
		public function save():void
		{
			if(!SETTING_FILE.exists)
			{
				var settingsXmlFile:File = File.applicationDirectory.resolvePath("templete/task/settings.xml");
				settingsXmlFile.copyTo(File.userDirectory.resolvePath("task/settings.xml"));
				SETTING_FILE = File.userDirectory.resolvePath("task/settings.xml");
				
				if(!DEFAULT_LOG_DIR.exists || !DEFAULT_LOG_DIR.isDirectory)
				{
					DEFAULT_LOG_DIR.createDirectory();
				}
			}
			
			Global.saveXml(settingXml, SETTING_FILE);
		}
	}
}
