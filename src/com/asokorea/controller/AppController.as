package com.asokorea.controller
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.TaskEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.enum.MainCurrentState;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.TaskVo;
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
			
			if(!appModel.hostFile || !appModel.hostFile.exists)
			{
				appModel.hostFile = File.userDirectory.resolvePath("task/_default_");
			}
			
			appModel.hostFile.addEventListener(Event.SELECT, onSelectHostList);
			appModel.hostFile.addEventListener(Event.CANCEL, onCancel)
			appModel.hostFile.browseForOpen("Select Host List", appModel.hostFileTypeFilter);
		}
		
		protected function onCancel(event:Event):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
			appModel.hostFile.removeEventListener(Event.SELECT, onSelectHostList);
			appModel.hostFile.removeEventListener(Event.CANCEL, onCancel)
		}
		
		[EventHandler(event="FileEventEX.HOSTLIST_FILE_LOAD")]
		public function loadHostList(event:FileEventEX):void
		{
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_BUSY;
			getHostList(event.file);
		}

		protected function onSelectHostList(event:Event):void
		{
			appModel.hostFile.removeEventListener(Event.SELECT, onSelectHostList);
			appModel.hostFile.removeEventListener(Event.CANCEL, onCancel)

			if (appModel.hostFile && appModel.hostFile.exists && !appModel.hostFile.isDirectory)
			{
				if(navModel.MAIN_CURRENT_SATAE != NavigationModel.MAIN_FIRST)
				{
					getHostList(appModel.hostFile);				
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
						hostMap[vo.ip] = vo;
						hostList.addItem(vo);
					}
				}
				appModel.hostList = hostList;
				appModel.hasHostList = true;
				appModel.selectedTaskVo.importHostListFile = appModel.hostFile.nativePath;
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
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_BUSY;
			
			multiSSH = new MultiSSH();
			multiSSH.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputSSH);
			multiSSH.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorSSH);
			multiSSH.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			multiSSH.addEventListener("notFoundJava", noJavaHandler);
			multiSSH.execute(event.taskVo);
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

				appModel.message = data;
				appModel.standardOutput = data;
				
				if(data.indexOf("[OUTPUT]") >= 0)
				{
					var result:Object = JSON.parse(data.replace(/\[OUTPUT\]/,""));
					var taskVo:TaskVo = appModel.selectedTaskVo;
					var hostVo:HostVo = hostMap[result["ip"]] as HostVo;

					
					trace("## JSON : ", result);
					appModel.standardOutput = "[timeStamp] " + result["timeStamp"] + File.lineEnding;
					appModel.standardOutput += "[ip] " + result["ip"] + File.lineEnding;
					appModel.standardOutput += "[hostName] " + result["hostName"] + File.lineEnding;
					appModel.standardOutput += "[fileName] " + result["fileName"] + File.lineEnding;
					appModel.standardOutput += "[dataSize] " + result["dataSize"] + File.lineEnding;
					appModel.standardOutput += "[message] " + result["message"];
					
						
//					var str:String = ssh.output;
//					var matches:Array = null;
//					var hostName:String = null;
//					var users:ArrayCollection = null;
//					
//					if(str)
//					{
//						if((matches = ssh.output.match(/hostname .+/)) && matches.length > 0)
//						{
//							hostName = matches[0].toString().replace(/hostname /,"");
//						}
//						
//						matches = ssh.output.match(/username .+/g);
//						
//						if(matches)
//						{
//							users = new ArrayCollection();
//							
//							for (var i:int = 0; i < matches.length; i++) 
//							{
//								var user:UserVo = new UserVo();
//								var arr:Array = matches[i].split(" ");
//								user.no = i + 1;
//								user.userName = arr[1];
//								user.privilege = arr[3];
//								user.secret = arr[5]
//								user.hash = arr[6];
//								users.addItem(user);
//							}
//						}
//					}
//					
//					currentItem.hostName = hostName;
//					currentItem.label = ssh.output;
//					currentItem.onLine = !!(currentItem.label);
//					currentItem.userList = users;
//					
//					trace(ssh.output);
//					
//					if(list)
//					{
//						appModel.hostList = list;
//						appModel.hostList.refresh();
//					}
//					
					
					
				}
			}
			
//			var out:String = "";
//			var currentItem:HostVo = list.getItemAt(currenPosition) as HostVo;
//			

//			
//			var e:LoopEvent = new LoopEvent(LoopEvent.DO_LOOP, list, ++currenPosition);
//			doAsyncChain(e);
		}
		
		protected function onErrorSSH(event:ProgressEvent):void
		{
			appModel.standardError = multiSSH.error;
		}		
	}
}