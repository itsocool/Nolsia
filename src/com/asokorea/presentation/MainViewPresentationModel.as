package com.asokorea.presentation
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.HostEvent;
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.util.Global;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	
	import mx.controls.Alert;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.events.CloseEvent;
	import mx.events.ListEvent;
	
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

		public function goFirst():void
		{
			appModel.settingsVo.load();
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_FIRST;
		}
		
		public function editSettings():void
		{
			appModel.settingsVo.load();
			dispatcher.dispatchEvent(new Event("editSettings"));
		}
		
		public function taskAdd():void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.ADD, null));
		}
		
		public function taskOpen(taskVo:TaskVo):void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.OPEN, taskVo));
		}
		
		public function taskEdit(taskVo:TaskVo):void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.EDIT, taskVo));
		}
		
		public function taskDelete(taskVo:TaskVo):void
		{
			dispatcher.dispatchEvent(new TaskEvent(TaskEvent.DELETE, taskVo));
		}
		
		public function browseHostList():void
		{
			var e:FileEventEX = new FileEventEX(FileEventEX.HOSTLIST_FILE_BROWSE, appModel.selectedHostListFile);
			dispatcher.dispatchEvent(e);
		}

		public function browseLogDir():void
		{
			var file:File = null;
			
			if(appModel.selectedTaskVo && appModel.selectedTaskVo.logPath)
			{
				file = new File(appModel.selectedTaskVo.logPath);
				
				if(!file || !file.exists || !file.isDirectory)
				{
					file = Global.DEFAULT_LOG_DIR;
				}
			}
			
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
			appModel.selectedTaskVo.hostList = null;
			appModel.hostCount = 0;
			appModel.successHostCount = 0;
			appModel.failHostCount = 0;
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
		
		public function hostSetDefault(hostVo:HostVo):void
		{
			dispatcher.dispatchEvent(new HostEvent(HostEvent.SET_DEFAULT, hostVo));
		}
		
		public function openFile(path:String):void
		{
			var file:File = new File(path);
			file.openWithDefaultApplication();
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
		}
		
		public function update():void
		{
			if(appModel.updater && appModel.updater.updateUrl)
			{
				navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_UPDATE;
				appModel.updater.downloadUpdate();
			}
		}
		
		public function abortUpdate():void
		{
			appModel.updater.abort();
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		public function exit():void
		{
			Alert.show("Are you sure?", "Alert", Alert.YES | Alert.NO, null, function(event:CloseEvent):void{
				if(event.detail == Alert.YES)
				{
					appModel.settingsVo.save();
					appModel.selectedTaskVo.save();
					NativeApplication.nativeApplication.exit();
				}
			});
		}
		
		public function analysisUsers():void
		{
			dispatcher.dispatchEvent(new Event("analysisUsers"));
		}
		
		public function openUsersReport():void
		{
			dispatcher.dispatchEvent(new Event("openUsersReport"));
		}
		
		public function exportExcel():void
		{
			dispatcher.dispatchEvent(new Event("exportExcel"));
		}
	}
}