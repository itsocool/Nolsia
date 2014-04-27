package com.asokorea.controller
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.HostEvent;
	import com.asokorea.event.MultiSSHEvent;
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.NativeUpdater;
	import com.asokorea.util.Excel2Xml;
	import com.asokorea.util.MultiSSH;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.utils.StringUtil;
	
	public class HostListController
	{
		[Inject]
		public var appModel:AppModel;
		
		[Inject]
		public var navModel:NavigationModel;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		[PostConstruct]
		public function init():void
		{
		}
		
		[EventHandler(event="FileEventEX.HOSTLIST_FILE_BROWSE")]
		public function browseHostList(event:FileEventEX):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_BUSY;
			
			if(!appModel.selectedHostListFile || !appModel.selectedHostListFile.exists)
			{
				appModel.selectedHostListFile = File.userDirectory.resolvePath("task/_default_");
			}
			
			appModel.selectedHostListFile.addEventListener(Event.SELECT, onSelectHostList);
			appModel.selectedHostListFile.addEventListener(Event.CANCEL, onCancel)
			appModel.selectedHostListFile.browseForOpen("Select Host List", appModel.hostFileTypeFilter);
		}
		
		[EventHandler(event="FileEventEX.LOG_DIRECTORY_BROWSE")]
		public function browseLogDir(event:FileEventEX):void
		{
			var logDir:File = event.file;
			if(!logDir || !logDir.exists || !logDir.isDirectory)
			{
				logDir = appModel.settingsVo.defaultLogDir;
				logDir.browseForDirectory("Select Log Directory");
				logDir.addEventListener(Event.SELECT, function(evt:Event):void{
					appModel.selectedTaskVo.logPath = logDir.nativePath;
					appModel.selectedTaskVo.save();
				});
			}
		}
		
		protected function onCancel(event:Event):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
			appModel.selectedHostListFile.removeEventListener(Event.SELECT, onSelectHostList);
			appModel.selectedHostListFile.removeEventListener(Event.CANCEL, onCancel)
		}
		
		[EventHandler(event="FileEventEX.HOSTLIST_FILE_LOAD")]
		public function loadHostList(event:FileEventEX):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_BUSY;
			getHostList(event.file);
		}
		
		protected function onSelectHostList(event:Event):void
		{
			appModel.selectedHostListFile.removeEventListener(Event.SELECT, onSelectHostList);
			appModel.selectedHostListFile.removeEventListener(Event.CANCEL, onCancel)
			
			if (appModel.selectedHostListFile && appModel.selectedHostListFile.exists && !appModel.selectedHostListFile.isDirectory)
			{
				appModel.selectedTaskVo.importHostListFile = appModel.selectedHostListFile.nativePath;
				appModel.selectedTaskVo.save();
				if(navModel.MAIN_CURRENT_SATAE != NavigationModel.MAIN_FIRST)
				{
					getHostList(appModel.selectedHostListFile);				
				}
			}
		}
		
		private function getHostList(hostFile:File):void
		{
			appModel.hostCount = 0;
			appModel.successHostCount = 0;
			appModel.failHostCount = 0;
			
			var excel2xml:Excel2Xml = new Excel2Xml()
			appModel.excel2Xml = excel2xml;
			excel2xml.addEventListener(Event.COMPLETE, onOutputXmlData);
			excel2xml.addEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
			excel2xml.addEventListener("notFoundJava", noJavaHandler);
			excel2xml.init(hostFile);
			excel2xml.convertXML();
		}
		
		protected function noJavaHandler(event:Event):void
		{
			var excel2xml:Excel2Xml = appModel.excel2Xml;
			
			if(excel2xml)
			{
				excel2xml.removeEventListener(Event.COMPLETE, onOutputXmlData);
				excel2xml.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
				excel2xml.removeEventListener("notFoundJava", noJavaHandler);
				excel2xml.dispose();
				excel2xml = null;
			}
			
			closeExcel2Xml();
			closeMSSH();
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_FIRST;			
			
			Alert.show("Not Found Java Runtime\nDo you want to download?","Warning", Alert.YES|Alert.NO, null, function(evt:CloseEvent):void{
				if(evt.detail == Alert.YES)
				{
					navigateToURL(new URLRequest("http://java.com/download"));
					return;
				}
			});
		}

		
		public function onOutputXmlData(event:Event):void
		{
			var excel2xml:Excel2Xml = appModel.excel2Xml;
			var data:String = excel2xml.output;
			var xml:XML = new XML(data);
			
			appModel.selectedTaskVo.hostListXml = xml;
			
			appModel.selectedTaskVo.hostList = null;
			appModel.hasHostList = !!appModel.selectedTaskVo.hostList;
			
			if(appModel.selectedTaskVo.hostList)
			{
				appModel.hostCount = appModel.selectedTaskVo.hostList.length;
			}else
			{
				appModel.hostCount = 0;
			}
			
			closeExcel2Xml();
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		public function onErrorXmlData(event:ProgressEvent):void
		{
			closeExcel2Xml();
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler( event="TaskEvent.EXECUTE" )]
		public function executeTask(event:TaskEvent) : void
		{
			var logDir:File = null;
			
			if(appModel.selectedTaskVo && appModel.selectedTaskVo.logPath)
			{
				logDir = new File(appModel.selectedTaskVo.logPath);
			}

			if(!logDir || !logDir.exists || !logDir.isDirectory)
			{
				logDir = appModel.settingsVo.defaultLogDir;
				logDir.createDirectory();
				logDir.browseForDirectory("Select Log Directory");
				logDir.addEventListener(Event.SELECT, function(evt:Event):void{
					appModel.selectedTaskVo.logPath = logDir.nativePath;
					appModel.selectedTaskVo.save();
					Alert.show("Setting complete!");
				});
				return;
			}
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_PROCESS;
			
			for each (var hostVo:HostVo in appModel.selectedTaskVo.hostList) 
			{
				hostVo.hostName = null;
				hostVo.isComplete = false;
				hostVo.isConnected = false;
				hostVo.isDefault = false;
				hostVo.logFile = null;
				hostVo.userList = null;
				hostVo.userMap = null;
			}

			multiSSH = new MultiSSH();
			multiSSH.addEventListener(MultiSSHEvent.CONNECTED, onSSHConnected);
			multiSSH.addEventListener(MultiSSHEvent.COMPELETE, onSSHCompelete);
			multiSSH.addEventListener(MultiSSHEvent.MESSAGE, onSSHMessage);
			multiSSH.addEventListener(MultiSSHEvent.LOGIN_FAIL, onSSHError);
			multiSSH.addEventListener(MultiSSHEvent.TIMEOUT, onSSHError);
			multiSSH.addEventListener(MultiSSHEvent.SSH_ERROR, onSSHError);
			multiSSH.addEventListener(MultiSSHEvent.EXCEPTION, onSSHError);
			multiSSH.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			multiSSH.addEventListener("notFoundJava", noJavaHandler);
			multiSSH.execute(event.taskVo);
		}
		
		protected function onSSHConnected(event:MultiSSHEvent):void
		{
			trace("onSSHConnected");
			var eventHostVo:HostVo = event.hostVo;
			var hostVo:HostVo = null;
			var result:String = "";
			
			if(eventHostVo && eventHostVo.ip && hostMap[eventHostVo.ip] is HostVo)
			{
				hostVo = hostMap[eventHostVo.ip] as HostVo;
				hostVo.isConnected = true;
				
				if(event.data)
				{
					result = StringUtil.trim(event.data);
				}
				
				appModel.standardOutput = result + "\n";			
			}
		}
		
		protected function onSSHCompelete(event:MultiSSHEvent):void
		{
			trace("onSSHCompelete");
			var eventHostVo:HostVo = event.hostVo;
			var hostVo:HostVo = null;
			var result:String = "";
			
			if(eventHostVo && eventHostVo.ip && hostMap[eventHostVo.ip] is HostVo && eventHostVo.logFile is File && eventHostVo.logFile.exists)
			{
				hostVo = hostMap[eventHostVo.ip] as HostVo;
				hostVo.isComplete = true;
				hostVo.hostName = eventHostVo.hostName;
				hostVo.logFile = eventHostVo.logFile;
				
				if(event.data)
				{
					result = StringUtil.trim(event.data);
				}
				
				appModel.standardOutput = result + "\n";			
			}
		}
		
		protected function onSSHMessage(event:MultiSSHEvent):void
		{
			trace("onSSHMessage");
			appModel.standardOutput = StringUtil.trim(event.data) + "\n";			
		}
		
		protected function onSSHError(event:MultiSSHEvent):void
		{
			trace("onSSHError");
			appModel.standardOutput = StringUtil.trim(event.data) + "\n";			
		}
		
		[EventHandler( event="TaskEvent.STOP" )]
		public function stopTask(event:TaskEvent) : void
		{
			closeMSSH();
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler( event="HostEvent.SET_DEFAULT" )]
		public function hostSetDefault(event:HostEvent) : void
		{
			if(event.hostVo is HostVo)
			{
				for each (var hostVo:HostVo in appModel.selectedTaskVo.hostList) 
				{
					hostVo.equalsToDefaultUser(event.hostVo);
				}
				
				appModel.selectedTaskVo.hostList.refresh();
			}
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			closeMSSH();
			
			appModel.successHostCount = 0;
			
			for each (var hostVo:HostVo in appModel.selectedTaskVo.hostList) 
			{
				if(hostVo.isComplete)
				{
					appModel.successHostCount ++;
				}
			}
			
			appModel.failHostCount = appModel.hostCount - appModel.successHostCount;
			appModel.standardOutput = "Task Completed!";
			Alert.show("Task Completed!");
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		private function closeExcel2Xml():void
		{
			var excel2xml:Excel2Xml = appModel.excel2Xml;
			
			if(excel2xml)
			{
				excel2xml.removeEventListener(Event.COMPLETE, onOutputXmlData);
				excel2xml.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
				excel2xml.removeEventListener("notFoundJava", noJavaHandler);
				excel2xml.dispose();
				excel2xml = null;
			}
		}		
		
		protected function closeMSSH():void
		{
			var multiSSH:MultiSSH = appModel.multiSSH;
			
			if(multiSSH)
			{
				multiSSH.removeEventListener(MultiSSHEvent.CONNECTED, onSSHConnected);
				multiSSH.removeEventListener(MultiSSHEvent.COMPELETE, onSSHCompelete);
				multiSSH.removeEventListener(MultiSSHEvent.MESSAGE, onSSHMessage);
				multiSSH.removeEventListener(MultiSSHEvent.LOGIN_FAIL, onSSHError);
				multiSSH.removeEventListener(MultiSSHEvent.TIMEOUT, onSSHError);
				multiSSH.removeEventListener(MultiSSHEvent.SSH_ERROR, onSSHError);
				multiSSH.removeEventListener(MultiSSHEvent.EXCEPTION, onSSHError);
				multiSSH.removeEventListener("notFoundJava", noJavaHandler);
				multiSSH.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
				multiSSH.dispose();
			}
			
			multiSSH = null;
		}
	}
}