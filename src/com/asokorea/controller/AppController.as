package com.asokorea.controller
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.HostEvent;
	import com.asokorea.event.MultiSSHEvent;
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.enum.MainCurrentState;
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
	
	import org.swizframework.storage.SharedObjectBean;
	
	public class AppController
	{
		private var process:NativeProcess;
		
		[Inject]
		public var appModel:AppModel;
		
		[Inject]
		public var so:SharedObjectBean;
		
		[Inject]
		public var navModel:NavigationModel;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		private var excel2Xml:Excel2Xml;
		private var multiSSH:MultiSSH;
		private var hostMap:Dictionary = new Dictionary();		
		
		[PostConstruct]
		public function init():void
		{
			var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXml.namespace();
			
			appModel.appName = appXml.ns::name.toString();
			appModel.appVersionLabel = appXml.ns::versionLabel[0].toString();
			appModel.updater = new NativeUpdater();
			appModel.updater.init();
			navModel.MAIN_CURRENT_SATAE=MainCurrentState.FIRST;
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
			appModel.selectedHostListFile.browseForOpen("Select Host List", Excel2Xml.hostFileTypeFilter);
		}
		
		[EventHandler(event="FileEventEX.LOG_DIRECTORY_BROWSE")]
		public function browseLogDir(event:FileEventEX):void
		{
			var logDir:File = event.file;
			if(!logDir || !logDir.exists || !logDir.isDirectory)
			{
				logDir = SettingsVo.DEFAULT_LOG_DIR;
				logDir.browseForDirectory("Select Log Directory");
				logDir.addEventListener(Event.SELECT, function(evt:Event):void{
					appModel.selectedTaskVo.logPath = logDir.nativePath;
					appModel.selectedTaskVo.saveTask();
				});
			}
		}
		
		[EventHandler(event="FileEventEX.HOSTLIST_FILE_LOAD")]
		public function loadHostList(event:FileEventEX):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_BUSY;
			onSelectHostList(null);
		}
		
		protected function onCancel(event:Event):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
			appModel.selectedHostListFile.removeEventListener(Event.SELECT, onSelectHostList);
			appModel.selectedHostListFile.removeEventListener(Event.CANCEL, onCancel)
		}
		
		protected function onSelectHostList(event:Event):void
		{
			appModel.selectedHostListFile.removeEventListener(Event.SELECT, onSelectHostList);
			appModel.selectedHostListFile.removeEventListener(Event.CANCEL, onCancel)
				
			if (appModel.selectedHostListFile && appModel.selectedHostListFile.exists && !appModel.selectedHostListFile.isDirectory)
			{
				appModel.excel2Xml = new Excel2Xml(appModel.selectedTaskVo, appModel.selectedHostListFile);
				appModel.excel2Xml.addEventListener(Event.COMPLETE, onXMLComplete);
				appModel.excel2Xml.addEventListener("error", onXMLError);
				appModel.excel2Xml.addEventListener("notFoundJava", noJavaHandler);
				appModel.excel2Xml.execute();
			}
		}
		
		protected function onXMLComplete(event:Event):void
		{
			appModel.excel2Xml.removeEventListener(Event.COMPLETE, onXMLComplete);
			appModel.excel2Xml.removeEventListener("error", onXMLError);
			appModel.excel2Xml.removeEventListener("notFoundJava", noJavaHandler);
			
			appModel.selectedTaskVo.importHostListFile = appModel.excel2Xml.excelFile.nativePath;
			appModel.selectedTaskVo.saveHostListXml(appModel.excel2Xml.xml);
			appModel.selectedTaskVo.saveTask();
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		protected function onXMLError(event:Event):void
		{
			if(appModel.excel2Xml)
			{
				appModel.excel2Xml.removeEventListener(Event.COMPLETE, onXMLComplete);
				appModel.excel2Xml.removeEventListener("error", onXMLError);
				appModel.excel2Xml.removeEventListener("notFoundJava", noJavaHandler);
				appModel.excel2Xml.dispose()
				appModel.excel2Xml = null;
			}
			
			Alert.show("Excel Read Error");
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
//		private var excel2xml:Excel2Xml;
//		
//		private function getHostList(hostFile:File):void
//		{
//			appModel.hostCount = 0;
//			appModel.successHostCount = 0;
//			appModel.failHostCount = 0;
//			
//			excel2xml = new Excel2Xml();
//			excel2xml.addEventListener(Event.COMPLETE, onOutputXmlData);
//			excel2xml.addEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
//			excel2xml.addEventListener("notFoundJava", noJavaHandler);
//			excel2xml.init(hostFile);
//			excel2xml.convertXML();
//		}
		
		protected function noJavaHandler(event:Event):void
		{
			if(appModel.excel2Xml)
			{
				appModel.excel2Xml.removeEventListener(Event.COMPLETE, onXMLComplete);
				appModel.excel2Xml.removeEventListener("error", onXMLError);
				appModel.excel2Xml.removeEventListener("notFoundJava", noJavaHandler);
				appModel.excel2Xml.dispose()
				appModel.excel2Xml = null;
			}
			
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
		
//		public function onOutputXmlData(event:Event):void
//		{
//			excel2xml.removeEventListener(Event.COMPLETE, onOutputXmlData);
//			excel2xml.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
//			excel2xml.removeEventListener("notFoundJava", noJavaHandler);
//			
//			var data:String = excel2xml.output;
//			var xml:XML = new XML(data);
//			var taskVo:TaskVo = appModel.selectedTaskVo;
//			
//			appModel.hostList = null;
//			appModel.hasHostList = false;
//			
//			if (data && StringUtil.trim(data).length > 0 && xml is XML)
//			{
//				var fileStream:FileStream=new FileStream();
//				var vo:HostVo=null;
//				var hostList:ArrayCollection = new ArrayCollection;
//				
//				for (var i:int=0; i < xml.sheet[0].row.length(); i++)
//				{
//					var row:Object= xml.sheet[0].row[i];
//					
//					if(row && row.col && row.col[0].toString() && row.col[1].toString() && row.col[2].toString())
//					{
//						vo = new HostVo();
//						vo.no = i + 1;
//						vo.ip = row.col[0].toString();
//						
//						if(!vo.ip || vo.ip.search(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/) < 0)
//						{
//							continue;
//						}
//						
//						vo.user = row.col[1].toString() || taskVo.ssh.user;
//						vo.password = row.col[2].toString() || taskVo.ssh.password;
//						vo.port ||= 22;
//						vo.taskName = taskVo.taskName;
//						hostMap[vo.ip] = vo;
//						hostList.addItem(vo);
//					}
//				}
//				appModel.hostList = hostList;
//				appModel.hasHostList = true;
//				appModel.selectedTaskVo.excelHostListFilePath = appModel.selectedHostListFile.nativePath;
//				appModel.selectedTaskVo.saveHostListXml(xml);
//				appModel.selectedTaskVo.saveTask();
//				
//				if(hostList)
//				{
//					appModel.hostCount = hostList.length;
//				}else
//				{
//					appModel.hostCount = 0;
//				}
//			}
//			
//			if(excel2xml)
//			{
//				excel2xml.dispose();
//				excel2xml = null;
//			}
//			
//			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
//		}
//		
//		public function onErrorXmlData(event:ProgressEvent):void
//		{
//			
//			var stdOut:IDataInput=process.standardError;
//			var data:String=stdOut.readMultiByte(stdOut.bytesAvailable, "EUC-KR");
//			
//			process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputXmlData);
//			process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorXmlData);
//			
//			if(process && process.running)
//			{
//				process.exit(true);
//			}
//			
//			process = null;
//			
//			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
//		}
		
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
				logDir = SettingsVo.DEFAULT_LOG_DIR;
				logDir.createDirectory();
				logDir.browseForDirectory("Select Log Directory");
				logDir.addEventListener(Event.SELECT, function(evt:Event):void{
					appModel.selectedTaskVo.logPath = logDir.nativePath;
					appModel.selectedTaskVo.saveTask();
					Alert.show("Setting complete!");
				});
				return;
			}
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_PROCESS;
			
			for each (var hostVo:HostVo in appModel.excel2Xml.hostList) 
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
				
				appModel.terminalOutput = result + "\n";			
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
				
				appModel.terminalOutput = result + "\n";			
			}
		}
		
		protected function onSSHMessage(event:MultiSSHEvent):void
		{
			trace("onSSHMessage");
			appModel.terminalOutput = StringUtil.trim(event.data) + "\n";			
		}
		
		protected function onSSHError(event:MultiSSHEvent):void
		{
			trace("onSSHError");
			appModel.terminalOutput = StringUtil.trim(event.data) + "\n";			
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
				for each (var hostVo:HostVo in appModel.excel2Xml.hostList) 
				{
					hostVo.equalsToDefaultUser(event.hostVo);
				}
				
				appModel.excel2Xml.hostList.refresh();
			}
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			
			appModel.successHostCount = 0;
			
			for each (var hostVo:HostVo in appModel.excel2Xml.hostList) 
			{
				if(hostVo.isComplete)
				{
					appModel.successHostCount ++;
				}
			}
			
			appModel.failHostCount = appModel.excel2Xml.hostCount - appModel.successHostCount;
			appModel.terminalOutput = "Task Completed!";
			Alert.show("Task Completed!");
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
			closeMSSH();
		}
		
		protected function closeMSSH():void
		{
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