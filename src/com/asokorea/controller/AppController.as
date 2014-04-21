package com.asokorea.controller
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.HostEvent;
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.enum.MainCurrentState;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.model.vo.UserVo;
	import com.asokorea.util.Excel2Xml;
	import com.asokorea.util.Global;
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
	import mx.collections.Sort;
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
		
		private var multiSSH:MultiSSH;
		private var hostMap:Dictionary = new Dictionary();		
		
		[PostConstruct]
		public function init():void
		{
			var appXml:XML=NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace=appXml.namespace();
			
			appModel.appName=appXml.ns::name.toString();
			appModel.appVersionLabel=appXml.ns::versionLabel[0].toString();
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
			appModel.selectedHostListFile.browseForOpen("Select Host List", appModel.hostFileTypeFilter);
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
				appModel.selectedTaskVo.saveTask();
				if(navModel.MAIN_CURRENT_SATAE != NavigationModel.MAIN_FIRST)
				{
					getHostList(appModel.selectedHostListFile);				
				}
			}
		}
		
		private var excel2xml:Excel2Xml;
		
		private function getHostList(hostFile:File):void
		{
			excel2xml = new Excel2Xml();
			excel2xml.addEventListener(Event.COMPLETE, onOutputXmlData);
			excel2xml.addEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
			excel2xml.addEventListener("notFoundJava", noJavaHandler);
			excel2xml.init(hostFile);
			excel2xml.convertXML();
		}
		
		protected function noJavaHandler(event:Event):void
		{
			if(excel2xml)
			{
				excel2xml.removeEventListener(Event.COMPLETE, onOutputXmlData);
				excel2xml.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
				excel2xml.removeEventListener("notFoundJava", noJavaHandler);
				excel2xml.dispose();
				excel2xml = null;
			}
			
			if(multiSSH)
			{
				multiSSH.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputSSH);
				multiSSH.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorSSH);
				multiSSH.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
				multiSSH.removeEventListener("notFoundJava", noJavaHandler);
				multiSSH.dispose();
				multiSSH = null;
			}
			
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
			excel2xml.removeEventListener(Event.COMPLETE, onOutputXmlData);
			excel2xml.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
			excel2xml.removeEventListener("notFoundJava", noJavaHandler);
			
			var data:String = excel2xml.output;
			var xml:XML = new XML(data);
			var taskVo:TaskVo = appModel.selectedTaskVo;
			
			appModel.hostList = null;
			appModel.hasHostList = false;
			
			if (data && StringUtil.trim(data).length > 0 && xml is XML)
			{
				var fileStream:FileStream=new FileStream();
				var vo:HostVo=null;
				var hostList:ArrayCollection = new ArrayCollection;
				
				for (var i:int=0; i < xml.sheet[0].row.length(); i++)
				{
					var row:Object= xml.sheet[0].row[i];
					
					if(row && row.col && row.col[0].toString() && row.col[1].toString() && row.col[2].toString())
					{
						vo = new HostVo();
						vo.no = i + 1;
						vo.ip = row.col[0].toString();
						vo.user = row.col[1].toString() || taskVo.ssh.user;
						vo.password = row.col[2].toString() || taskVo.ssh.password;
						vo.port ||= 22;
						vo.taskName = taskVo.taskName;
						hostMap[vo.ip] = vo;
						hostList.addItem(vo);
					}
				}
				appModel.hostList = hostList;
				appModel.hasHostList = true;
				appModel.selectedTaskVo.importHostListFile = appModel.selectedHostListFile.nativePath;
				appModel.selectedTaskVo.saveHostListXml(xml);
				appModel.selectedTaskVo.saveTask();
			}
			
			if(excel2xml)
			{
				excel2xml.dispose();
				excel2xml = null;
			}
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		public function onErrorXmlData(event:ProgressEvent):void
		{
			
			var stdOut:IDataInput=process.standardError;
			var data:String=stdOut.readMultiByte(stdOut.bytesAvailable, "EUC-KR");
			
			process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputXmlData);
			process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorXmlData);
			
			if(process && process.running)
			{
				process.exit(true);
			}
			
			process = null;
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler( event="TaskEvent.EXECUTE" )]
		public function executeTask(event:TaskEvent) : void
		{
			if(!appModel.selectedTaskVo || !appModel.selectedTaskVo.logPath)
			{
				var logDir:File = SettingsVo.DEFAULT_LOG_DIR;
				logDir.browseForDirectory("Select Log Directory");
				logDir.addEventListener(Event.SELECT, function(evt:Event):void{
					appModel.selectedTaskVo.logPath = logDir.nativePath;
					appModel.selectedTaskVo.saveTask();
				});
			}
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_PROCESS;
			
			multiSSH = new MultiSSH();
			multiSSH.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputSSH);
			multiSSH.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorSSH);
			multiSSH.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			multiSSH.addEventListener("notFoundJava", noJavaHandler);
			multiSSH.execute(event.taskVo);
		}
		
		[EventHandler( event="TaskEvent.STOP" )]
		public function stopTask(event:TaskEvent) : void
		{
			if(multiSSH)
			{
				multiSSH.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputSSH);
				multiSSH.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorSSH);
				multiSSH.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
				multiSSH.removeEventListener("notFoundJava", noJavaHandler);
				multiSSH.dispose();
			}
			
			multiSSH = null;
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler( event="HostEvent.SET_DEFAULT" )]
		public function hostSetDefault(event:HostEvent) : void
		{
			if(event.hostVo is HostVo)
			{
				for each (var hostVo:HostVo in appModel.hostList) 
				{
					hostVo.equalsToDefaultUser(event.hostVo);
				}
				
				var sort:Sort = new Sort();
				sort.fields = ["isDefault"];
				sort.compareFunction = function(obj1:Object, obj2:Object):int{
					var result:int = 0;
					if(obj1 > obj2) result = 1;
					if(obj1 < obj2) result -1;
					return result;
				} 
				appModel.hostList.sort = sort;
				appModel.hostList.refresh();
			}
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			multiSSH.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputSSH);
			multiSSH.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorSSH);
			multiSSH.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			multiSSH.removeEventListener("notFoundJava", noJavaHandler);
			
			if(multiSSH)
			{
				multiSSH.dispose();
			}
			
			multiSSH = null;
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		protected function onOutputSSH(event:Event):void{
			
			var data:String = null;
			
			if(multiSSH.output)
			{
				data = multiSSH.output;
				
				var obj:Object = null;
				var taskVo:TaskVo = null;
				var hostVo:HostVo = null;
				var lines:Array = data.replace(/\r\n/,"\n").split("\n");
				var terminalOutput:String = null;
				
				for each (var line:String in lines) 
				{
					if(!line || !StringUtil.trim(line))
					{
						continue;
					}
					
					var ip:String = null;
					obj = getObjectFromJSON(line);
					
					if(obj)
					{
						ip = obj["result"]["ip"].toString();
						if(obj["type"] == "CONNECTED")
						{
							hostVo = hostMap[ip] as HostVo;
							hostVo.isConnected = true;
							terminalOutput = StringUtil.substitute("[CONNECTED] {0}", ip);
						}else if(obj["type"] == "OUTPUT")
						{
							hostVo = hostMap[ip] as HostVo;
							taskVo = appModel.selectedTaskVo;
							hostVo.hostName = obj["result"]["hostName"].toString();
							hostVo.isComplete = true;
							hostVo.logFile = new File(taskVo.logPath).resolvePath(obj["result"]["fileName"]);
							terminalOutput = StringUtil.substitute("[OUTPUT] {0} {1}", ip, hostVo.hostName);    
						}		
					}else{
						terminalOutput = line;
					}					
					
					appModel.terminalOutput = terminalOutput + "\n";    
					appModel.hostList.refresh();
				}
			}
		}
		
		protected function getObjectFromJSON(outputLine:String):Object
		{
			var result:Object = null;
			
			if(outputLine.indexOf("[CONNECTED]") >= 0)
			{
				result = JSON.parse('{"type":"CONNECTED","result":' + outputLine.replace(/\[CONNECTED]/,"") + '}');
			}else if(outputLine.indexOf("[OUTPUT]") >= 0)
			{
				result = JSON.parse('{"type":"OUTPUT","result":' + outputLine.replace(/\[OUTPUT\]/,"") + '}');
			}
			
			return result;
		}
		
		protected function onErrorSSH(event:ProgressEvent):void
		{
			appModel.terminalOutput = multiSSH.error;
		}		
	}
}