package com.asokorea.controller
{
	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.LoopEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.model.NavigationModel;
	import com.asokorea.model.enum.MainCurrentState;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.model.vo.UserVo;
	import com.asokorea.util.Excel2Xml;
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

		private var host:HostVo = null;
		private var currenPosition:int = -1;
		private var lastPosition:int = -1;
		private var list:ArrayCollection = null;
		
		private var ssh:JSSH;
		private var commandFile:String;
		
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
			appModel.hostFile = (appModel.hostFile && appModel.hostFile.exists) ? appModel.hostFile : File.userDirectory;
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
			
			if(ssh)
			{
				ssh.removeEventListener(Event.COMPLETE, onOutputSSH);
				ssh.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorSSH);
				ssh.removeEventListener("notFoundJava", noJavaHandler);
				ssh.dispose();
				ssh = null;
			}
			
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_FIRST;			
			
			Alert.show("Not Found Java\nWould you download now?","Warning", Alert.YES|Alert.NO, null, function(evt:CloseEvent):void{
				if(evt.detail == Alert.YES)
				{
					navigateToURL(new URLRequest("http://java.com/download"));
					return;
				}
			});
		}
		
		private var sdt:Date;
		private var edt:Date;
		
		public function onOutputXmlData(event:Event):void
		{
			excel2xml.removeEventListener(Event.COMPLETE, onOutputXmlData);
			excel2xml.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorXmlData);
			excel2xml.removeEventListener("notFoundJava", noJavaHandler);
			
			var data:String = excel2xml.output;
			var xml:XML = new XML(data);
			
			appModel.hostList = null;
			appModel.hasHostList = false;
			
			if (data && StringUtil.trim(data).length > 0 && xml is XML)
			{
				var fileStream:FileStream=new FileStream();
				var vo:HostVo=null;
				var hostList:ArrayCollection = new ArrayCollection;
				
				commandFile = "command.sh";
				
				for (var i:int=0; i < xml.sheet[0].row.length(); i++)
				{
					var row:Object= xml.sheet[0].row[i];
					
					if(row && row.col && row.col[0].toString() && row.col[1].toString() && row.col[2].toString())
					{
						vo=new HostVo();
						vo.no=i + 1;
						vo.ip=row.col[0].toString();
						vo.loginId=row.col[1].toString();
						vo.password=row.col[2].toString();
						vo.port ||= 22;
						vo.commandFile = commandFile;
						
						hostList.addItem(vo);
					}
				}
				appModel.hostList = hostList;
				appModel.hasHostList = true;
				appModel.selectedTask.importHostListFile = appModel.hostFile.nativePath;
				appModel.selectedTask.saveHostListXml(xml);
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
		
		[EventHandler( event="LoopEvent.DO_LOOP" )]
		public function doAsyncChain(event:LoopEvent) : void
		{
			sdt ||= new Date();
			
			currenPosition = event.currentPosition;
			lastPosition = event.lastPosition;

			if(currenPosition < lastPosition + 1)
			{
				loopStart(event);	
			}else{
				loopStop(event);
			}
		}
		
		protected var _startupInfo:NativeProcessStartupInfo;
		
		private function loopStart(event:LoopEvent):void
		{
			list = event.list;
			host = event.currentItem as HostVo;
			lastPosition = event.lastPosition;

			if(ssh)
			{
				ssh.dispose();
			}
			
			ssh = null;
			ssh = new JSSH();
			ssh.addEventListener(Event.COMPLETE, onOutputSSH);
			ssh.addEventListener(Event.STANDARD_ERROR_CLOSE, onErrorSSH);
			ssh.addEventListener("notFoundJava", noJavaHandler);
			ssh.init(host);
			ssh.execute();
		}
		
		private function loopStop(event:LoopEvent):void
		{
			var host:HostVo = event.currentItem as HostVo;
			var currenPosition:int = event.currentPosition;
			var lastPosition:int = event.lastPosition;
			var list:ArrayCollection = event.list;
			
			if(ssh)
			{
				_startupInfo = null;
				ssh.removeEventListener(Event.COMPLETE, onOutputSSH);
				ssh.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorSSH);
				ssh.removeEventListener("notFoundJava", noJavaHandler);
				ssh.dispose();
				ssh = null;
			}
			
			trace("Exit SSH");
			edt = new Date();
			
			Alert.show("Done ! " + (edt.time - sdt.time) + "ms");
			sdt = null;
			edt = null;
				
		}
		
		protected function onOutputSSH(event:Event):void{

			var out:String = "";
			var currentItem:HostVo = list.getItemAt(currenPosition) as HostVo;
			
			if(ssh){
				ssh.removeEventListener(Event.COMPLETE, onOutputSSH);
				ssh.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorSSH);
				ssh.removeEventListener("notFoundJava", noJavaHandler);				
				
				var str:String = ssh.output;
				var matches:Array = null;
				var hostName:String = null;
				var users:ArrayCollection = null;
				
				if(str)
				{
					if((matches = ssh.output.match(/hostname .+/)) && matches.length > 0)
					{
						hostName = matches[0].toString().replace(/hostname /,"");
					}
					
					matches = ssh.output.match(/username .+/g);
				
					if(matches)
					{
						users = new ArrayCollection();
						
						for (var i:int = 0; i < matches.length; i++) 
						{
							var user:UserVo = new UserVo();
							var arr:Array = matches[i].split(" ");
							user.no = i + 1;
							user.userName = arr[1];
							user.privilege = arr[3];
							user.secret = arr[5]
							user.hash = arr[6];
							users.addItem(user);
						}
					}
				}

				currentItem.hostName = hostName;
				currentItem.label = ssh.output;
				currentItem.onLine = !!(currentItem.label);
				currentItem.userList = users;

				trace(ssh.output);

				if(list)
				{
					appModel.hostList = list;
					appModel.hostList.refresh();
				}
			}
			
			var e:LoopEvent = new LoopEvent(LoopEvent.DO_LOOP, list, ++currenPosition);
			doAsyncChain(e);
		}
		
		/**
		 * Process error handling...
		 * Sometimes stuff that's not an error comes through here... why? i'm not sure... but complete gets called eventually anyway.
		 **/ 
		protected function onErrorSSH(event:Event):void{
			
			var out:String = "";
			var currentItem:HostVo = list.getItemAt(currenPosition) as HostVo;
			
			if(ssh){
				ssh.removeEventListener(Event.COMPLETE, onOutputSSH);
				ssh.removeEventListener(Event.STANDARD_ERROR_CLOSE, onErrorSSH);
				ssh.removeEventListener("notFoundJava", noJavaHandler);				
				
				currentItem.label = ssh.error;
				currentItem.onLine = !!(ssh.output);
				
				trace(ssh.error);
				
				if(list)
				{
					appModel.hostList = list;
					appModel.hostList.refresh();
				}
			}			
			
			if(currenPosition < lastPosition + 1){
				var nextItem:* = list.getItemAt(currenPosition + 1);
				doAsyncChain(new LoopEvent(LoopEvent.DO_LOOP, list, nextItem));
			}
		}		
	}
}