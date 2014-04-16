package com.asokorea.controller
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.LoopEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.enum.MainCurrentState;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.supportclass.FileReader;
	import com.asokorea.util.Excel2Xml;
	import com.asokorea.util.Global;
	import com.asokorea.util.JSSH;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.IDataInput;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;
	
	import org.swizframework.storage.SharedObjectBean;

	public class TaskController
	{
		protected static const LOG:ILogger=Log.getLogger("TaskController");
		
		[PostConstruct]
		public function init():void
		{
			trace("TaskController init");
		}
		
		[EventHandler(event="TaskEvent.ADD")]
		public function addNewTask():void
		{
			Alert.show("ok new task");
		}
		
	}
}