package com.asokorea.model.vo
{
	import com.asokorea.util.Global;
	
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class SettingsVo
	{
		private var _defaultTaskName:String = Global.DEFAULT_TASK_NAME;
		private var _defaultLogDir:File = null;
		private var _taskList:ArrayCollection = null;
		private var _settingXml:XML = null;
		
		public function SettingsVo()
		{
			if(!_defaultLogDir || !_defaultLogDir.exists || !_defaultLogDir.isDirectory)
			{
				_defaultLogDir = Global.DEFAULT_LOG_DIR;
			}

			load();
		}

		public function getTaskVo(taskName:String):TaskVo
		{
			if(_taskList)
			{
				for each (var item:TaskVo in _taskList) 
				{
					if(item.taskName == taskName)
					{
						return item;
					}
				}
			}
			
			return null;
		}
		
		public function load():void
		{
			var logDir:File = null;
			var logPath:String = null
			var tasks:ArrayCollection = null;

			_settingXml = Global.readXml(Global.SETTING_FILE); 
			
			if(settingXml is XML && settingXml..taskRef is XMLList)
			{
				var taskXmlList:XMLList = settingXml..taskRef as XMLList;
				tasks = new ArrayCollection();
				
				for each (var taskRef:XML in taskXmlList) 
				{
					var taskName:String = taskRef.taskName.toString();
					var description:String = taskRef.description.toString();
					var taskBasePath:String = taskRef.taskBaseDir.toString();
					var taskVo:TaskVo = new TaskVo();
					var file:File = null;

					taskVo.load(taskName);
					taskVo.save();
					tasks.addItem(taskVo);
				}
			}

			logPath = settingXml.defaultLogDir.toString();
			
			if(logPath)
			{
				logDir = new File(logPath);
			}else
			{
				logDir = _defaultLogDir;
			}
			
			if(!logDir || !logDir.exists)
			{
				logDir.createDirectory();
			}
			
			defaultTaskName = settingXml.defaultTaskName.toString();
			_taskList = tasks;
			defaultLogDir = logDir;
		}

		public function save():void
		{
			reLoadTaskList();
			Global.saveXml(settingXml, Global.SETTING_FILE);
		}
		
		public function get taskList():ArrayCollection
		{
			return _taskList;
		}
		
		public function set taskList(value:ArrayCollection):void
		{
			reLoadTaskList();
			_taskList = value;
		}
		
		private function reLoadTaskList():void
		{
			if(settingXml)
			{
				settingXml.tasks = <tasks/>;
				
				for each (var taskVo:TaskVo in taskList) 
				{
					var taskRef:XML = <taskRef/>;
					taskRef.taskName = taskVo.taskName;
					taskRef.description = Global.cdata(taskVo.description, "description");
					taskRef.taskBaseDir = Global.cdata(taskVo.taskBaseDir.nativePath, "taskBaseDir");
					settingXml.tasks.appendChild(taskRef);
				}
			}
		}
		
		public function get defaultLogDir():File
		{
			return _defaultLogDir;
		}
		
		public function set defaultLogDir(value:File):void
		{
			if(settingXml)
			{
				settingXml.defaultLogDir = Global.cdata(value.nativePath, "defaultLogDir");
			}
			_defaultLogDir = value;
		}
		
		public function get defaultTaskName():String
		{
			return _defaultTaskName;
		}
		
		public function set defaultTaskName(value:String):void
		{
			if(settingXml)
			{
				settingXml.defaultTaskName = value;
			}
			
			_defaultTaskName = value;
		}
		
		public function get settingXml():XML
		{
			return _settingXml;
		}
		
		public function set settingXml(value:XML):void
		{
			load();
			_settingXml = value;
		}
	}
}
