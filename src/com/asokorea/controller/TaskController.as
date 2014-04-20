package com.asokorea.controller
{
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.LOG;
	
	import flash.filesystem.File;

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
			appModel.settingsVo = new SettingsVo();
			appModel.settingsVo.save();
		}
		
		[EventHandler(event="TaskEvent.ADD")]
		public function addNewTask():void
		{
			LOG.debug("Add New Task");
		}
		
		[EventHandler(event="TaskEvent.OPEN")]
		public function openTask(event:TaskEvent):void
		{
			LOG.debug("Open Task", event.taskVo.taskName);
			var task:TaskVo = event.taskVo;
			var hostFile:File = new File(task.importHostListFile);
			appModel.selectedTaskVo = task;
			appModel.hostFile = (task.importHostListFile && hostFile && hostFile.exists) ? hostFile : null;
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler(event="TaskEvent.EDIT")]
		public function editTask(event:TaskEvent):void
		{
			LOG.debug("Edit Task", event.taskVo.taskName);
		}
		
		[EventHandler(event="TaskEvent.DELETE")]
		public function deleteTask(event:TaskEvent):void
		{
			LOG.debug("Delete Task", event.taskVo.taskName);
		}
		
	}
}