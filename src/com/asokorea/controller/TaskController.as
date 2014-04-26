package com.asokorea.controller
{
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.TaskModel;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.LOG;
	import com.asokorea.util.Excel2Xml;
	import com.asokorea.view.form.SettingsForm;
	import com.asokorea.view.form.TaskForm;
	
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;

	public class TaskController
	{
		protected static var taskBaseDir:File = File.userDirectory.resolvePath("task");
		
		[Inject]
		public var appModel:AppModel;
		
		[Inject]
		public var navModel:NavigationModel;
		
		[Inject]
		public var taskModel:TaskModel;
		
		[PostConstruct]
		public function init():void
		{
			appModel.settingsVo = new SettingsVo();
			appModel.settingsVo.save();
		}
		
		[EventHandler(event="editSettings")]
		public function settingsEdit():void
		{
			var app:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
			taskModel.settingsForm = PopUpManager.createPopUp(app, SettingsForm, true) as SettingsForm;
			taskModel.settingsForm.settingsVo = appModel.settingsVo;
			PopUpManager.centerPopUp(taskModel.settingsForm);
			taskModel.settingsForm.addEventListener(CloseEvent.CLOSE, onCloseSettings);
		}
		
		protected function onCloseSettings(event:CloseEvent):void
		{
			taskModel.settingsForm.removeEventListener(CloseEvent.CLOSE, onCloseSettings);
			PopUpManager.removePopUp(taskModel.settingsForm);
		}
		
		[EventHandler(event="TaskEvent.ADD")]
		public function addNewTask(event:TaskEvent):void
		{
			var app:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
			taskModel.taskForm = PopUpManager.createPopUp(app, TaskForm) as TaskForm;
			PopUpManager.centerPopUp(taskModel.taskForm);
		}
		
		[EventHandler(event="TaskEvent.OPEN")]
		public function openTask(event:TaskEvent):void
		{
			LOG.debug("Open Task", event.taskVo.taskName);
			var task:TaskVo = event.taskVo;
			
			if(task && task.importHostListFile)
			{
				var hostFile:File = new File(task.importHostListFile);
				
				appModel.selectedTaskVo = task;
				
				if(task.importHostListFile && hostFile && hostFile.exists)
				{
					appModel.excel2Xml = new Excel2Xml(task, hostFile);
				}
			}
			
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