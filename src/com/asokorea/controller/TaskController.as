package com.asokorea.controller
{
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.vo.SshVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.LOG;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class TaskController
	{
		protected static var taskBaseDir:File = File.userDirectory.resolvePath("task");
		
		[Inject]
		public var appModel:AppModel;
		
		[Inject]
		public var navModel:NavigationModel;
		
		[PostConstruct]
		public function init():void
		{
			appModel.settings = getSettings();
		}
		
		public function getSettings():ArrayCollection
		{
			var result:ArrayCollection = null;
			var settingFile:File = taskBaseDir.resolvePath("settings.xml");
			var fileStream:FileStream = new FileStream();
			var settingXml:XML = null;
			
			if(!taskBaseDir.exists || !settingFile.exists)
			{
				var file:File = File.applicationDirectory.resolvePath("templete/task");
				file.copyTo(File.userDirectory.resolvePath("task"));
				taskBaseDir = File.userDirectory.resolvePath("task");
				settingFile = taskBaseDir.resolvePath("settings.xml");
			}
			
			fileStream.open(settingFile, FileMode.READ); 
			settingXml = XML(fileStream.readUTFBytes(fileStream.bytesAvailable)); 
			fileStream.close();
			
			if(settingXml is XML && settingXml..taskRef is XMLList)
			{
				var taskList:XMLList = settingXml..taskRef as XMLList;
				result = new ArrayCollection();
				
				for each (var taskRef:XML in taskList) 
				{
					var taskVo:TaskVo = new TaskVo();
					var taskName:String = taskRef.toString();
					var taskXml:XML = null;
					
					settingFile = taskBaseDir.resolvePath(taskName + "/config.xml");
					fileStream.open(settingFile, FileMode.READ); 
					taskXml = XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
					fileStream.close();
					
					taskVo.taskName = taskName;
					taskVo.description = taskRef.description.toString();
					
					taskVo.taskName = taskXml.taskName;
					taskVo.description = taskXml.description;
					
					var chkfile:File = null;
					chkfile = new File(taskXml.importHostListFile);
					taskVo.importHostListFile = (chkfile.exists) ? taskXml.importHostListFile : null;
					chkfile = new File(taskXml.exportedHostListFile);
					taskVo.exportedHostListFile = (chkfile.exists) ? taskXml.exportedHostListFile : null;
					chkfile = new File(taskXml.logPath);
					taskVo.logPath = (chkfile.exists && chkfile.isDirectory) ? taskXml.logPath : null;
					
					taskVo.ssh = new SshVo();
					taskVo.ssh.autoExit = taskXml.ssh.autoExit;
					taskVo.ssh.password = taskXml.ssh.password;
					taskVo.ssh.timeout = taskXml.ssh.timeout;
					taskVo.ssh.user = taskXml.ssh.user;
					taskVo.ssh.commads = new ArrayCollection();
					
					var commandList:XMLList = taskXml..command;

					for each (var command:XML in commandList) 
					{
						taskVo.ssh.commads.addItem(command.toString());
					}

					result.addItem(taskVo);
					LOG.debug(taskVo.ssh.commads[5]);
				}
			}
			
			return result;
		}
		
		[EventHandler(event="TaskEvent.ADD")]
		public function addNewTask():void
		{
			LOG.debug("Add New Task");
		}
		
		[EventHandler(event="TaskEvent.OPEN")]
		public function openTask(event:TaskEvent):void
		{
			LOG.debug("Open Task", event.task.taskName);
			var hostFile:File = new File(event.task.importHostListFile);
			appModel.selectedTask = event.task;
			appModel.hostFile = (event.task.importHostListFile && hostFile && hostFile.exists) ? hostFile : null;
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler(event="TaskEvent.EDIT")]
		public function editTask(event:TaskEvent):void
		{
			LOG.debug("Edit Task", event.task.taskName);
		}
		
		[EventHandler(event="TaskEvent.DELETE")]
		public function deleteTask(event:TaskEvent):void
		{
			LOG.debug("Delete Task", event.task.taskName);
		}
		
	}
}