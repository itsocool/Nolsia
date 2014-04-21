package com.asokorea.presentation
{

	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.FileReaderEvent;
	import com.asokorea.event.HostEvent;
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.FileExtensionFilter;
	import com.asokorea.supportclass.FileReader;
	import com.asokorea.supportclass.IFilter;
	import com.asokorea.util.Global;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.events.ListEvent;
	
	/**
	 * 
	 * @author developer
	 */
	/**
	 * 
	 * @author developer
	 */
	public class MainViewPresentationModel extends EventDispatcher
	{
		[Dispatcher]
		public var dispatcher:IEventDispatcher;

		[Bindable]
		[Inject]
		public var appModel:AppModel;

		[Bindable]
		[Inject]
		public var navModel:NavigationModel;

		public function addNewTask():void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.ADD));
		}
		
		public function taskOpen(task:TaskVo):void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.OPEN, task));
		}
		
		public function taskEdit(task:TaskVo):void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.EDIT, task));
		}
		
		public function taskDelete(task:TaskVo):void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.DELETE, task));
		}
		
		public function browseHostList():void
		{
			var e:FileEventEX = new FileEventEX(FileEventEX.HOSTLIST_FILE_BROWSE, appModel.selectedHostListFile);
			dispatcher.dispatchEvent(e);
		}

		public function browseLogDir():void
		{
			var file:File = (appModel.selectedTaskVo && appModel.selectedTaskVo.logPath) ? new File(appModel.selectedTaskVo.logPath) : null;
			var e:FileEventEX = new FileEventEX(FileEventEX.LOG_DIRECTORY_BROWSE, file);
			dispatcher.dispatchEvent(e);
		}
		
		public function loadHostList():void
		{
			var e:FileEventEX = new FileEventEX(FileEventEX.HOSTLIST_FILE_LOAD, appModel.selectedHostListFile);
			dispatcher.dispatchEvent(e);
		}
		
		public function clearHostList():void
		{
			appModel.hostList = null;
			appModel.hasHostList = false;
		}
		
		public function start():void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.EXECUTE, appModel.selectedTaskVo));
		}
		
		public function stop():void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.STOP, appModel.selectedTaskVo));
		}
		
		public function hostItemClick(event:ListEvent):void
		{
			var grid:DataGrid = event.itemRenderer.owner as DataGrid;
			var col:DataGridColumn = grid.columns[event.columnIndex] as DataGridColumn;
			
			if(grid is DataGrid && col.dataField == "isDefault")
			{
				var hostVo:HostVo = grid.selectedItem as HostVo;
				dispatcher.dispatchEvent(new HostEvent(HostEvent.SET_DEFAULT, hostVo));
			}
		}
		
		public function openLogDir(logPath:String):void
		{
			var logDir:File = new File(logPath);
			logDir.openWithDefaultApplication();
		}

		public static const CURRENT_STATE_CHANGED:String="currentStateChanged";

		private var _currentState:String;

		[Inject("navModel.MAIN_CURRENT_SATAE", bind="true")]
		[Bindable(event="currentStateChanged")]
		public function get currentState():String
		{
			return _currentState;
		}

		public function set currentState(value:String):void
		{
			if (_currentState != value)
			{
				_currentState=value;
				this.dispatchEvent(new Event(CURRENT_STATE_CHANGED));
			}
			trace(Global.classInfo);
		}
	}
}