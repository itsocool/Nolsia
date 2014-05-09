package com.asokorea.controller
{
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.TaskModel;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.LOG;
	import com.asokorea.view.form.SettingsForm;
	import com.asokorea.view.form.TaskForm;
	import com.asokorea.view.popups.TaskCopyPopup;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.filesystem.File;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;

	public class TaskController
	{
		
		[Inject]
		public var appModel:AppModel;
		
		[Inject]
		public var navModel:NavigationModel;
		
		[Inject]
		public var taskModel:TaskModel;
		
		[PostConstruct]
		public function init():void
		{
			if(!appModel.settingsVo)
			{
				appModel.settingsVo = new SettingsVo();
				appModel.settingsVo.save();
			}
		}
		
		[EventHandler(event="editSettings")]
		public function settingsEdit():void
		{
			var app:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
			appModel.settingsVo.load();
			taskModel.settingsForm = PopUpManager.createPopUp(app, SettingsForm, true) as SettingsForm;
			taskModel.settingsForm.settingsVo = appModel.settingsVo;
			PopUpManager.centerPopUp(taskModel.settingsForm);
		}
		
		[EventHandler(event="TaskEvent.ADD")]
		public function addNewTask(event:TaskEvent):void
		{
			var app:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
			taskModel.taskForm = PopUpManager.createPopUp(app, TaskForm) as TaskForm;
			taskModel.taskForm.taskVo = new TaskVo();
			taskModel.taskForm.currentState = NavigationModel.TASK_ADD;
			PopUpManager.centerPopUp(taskModel.taskForm);
		}
		
		[EventHandler(event="TaskEvent.COPY")]
		public function copyTask(event:TaskEvent):void
		{
			var app:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
			var sourceTaskVo:TaskVo = event.taskVo;
			var targetTaskVo:TaskVo = null;
			
			taskModel.taskCopyPopup = PopUpManager.createPopUp(app, TaskCopyPopup) as TaskCopyPopup;
			taskModel.taskCopyPopup.taskName = "Copy of " + sourceTaskVo.taskName;
			taskModel.taskCopyPopup.addEventListener("taskCopy", function(e:Event):void{
				targetTaskVo = sourceTaskVo.copyTask(taskModel.taskCopyPopup.taskName);
				appModel.settingsVo.taskList.addItem(targetTaskVo);
				appModel.settingsVo.taskList.refresh();
				appModel.settingsVo.save();
				taskModel.taskCopyPopup.close();
			});
			PopUpManager.centerPopUp(taskModel.taskCopyPopup);
		}
		
		[EventHandler(event="TaskEvent.OPEN")]
		public function openTask(event:TaskEvent):void
		{
			var task:TaskVo = event.taskVo;
			appModel.selectedTaskVo = task;
			
			if(task && task.importHostListFile)
			{
				var hostFile:File = new File(task.importHostListFile);
				appModel.selectedHostListFile = (task.importHostListFile && hostFile && hostFile.exists) ? hostFile : null;
			}
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler(event="TaskEvent.EDIT")]
		public function editTask(event:TaskEvent):void
		{
			var app:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
			taskModel.taskForm = PopUpManager.createPopUp(app, TaskForm) as TaskForm;
			taskModel.taskForm.taskVo = event.taskVo;
			taskModel.taskForm.currentState = NavigationModel.TASK_EDIT;
			PopUpManager.centerPopUp(taskModel.taskForm);
		}
		
		[EventHandler(event="TaskEvent.DELETE")]
		public function deleteTask(event:TaskEvent):void
		{
			Alert.show("Are you sure?", "Alert", Alert.YES | Alert.NO, null, function(e:CloseEvent):void{
				if(e.detail == Alert.YES)
				{
					var idx:int = appModel.settingsVo.taskList.getItemIndex(event.taskVo);
					appModel.settingsVo.taskList.removeItemAt(idx);
					appModel.settingsVo.save();
				}
			});
		}
	}
}