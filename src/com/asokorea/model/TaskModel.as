package com.asokorea.model
{
	import com.asokorea.view.form.SettingsForm;
	import com.asokorea.view.form.TaskForm;
	import com.asokorea.view.popups.TaskCopyPopup;

	[Bindable]
	public class TaskModel
	{
		public var settingsForm:SettingsForm;
		public var taskForm:TaskForm;
		public var taskCopyPopup:TaskCopyPopup;
	}
}
