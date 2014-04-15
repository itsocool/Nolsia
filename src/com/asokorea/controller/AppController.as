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

	public class AppController
	{
		protected static const LOG:ILogger=Log.getLogger("AppController");

		private var process:NativeProcess;
		
		[Inject]
		public var appModel:AppModel;

		[Inject]
		public var so:SharedObjectBean;

		[Inject]
		public var reader:FileReader;

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
			var hostPath:String=so.getString("DefaultHostPath");
			var logPath:String=so.getString("DefaultLogPath");

			var hostFile:File=(hostPath) ? new File(hostPath) : null;
			var logDir:File=(logPath) ? new File(logPath) : File.applicationDirectory;

			if (hostFile && !hostFile.isDirectory)
			{
				so.setString("DefaultHostPath", hostFile.nativePath);
			}
			else
			{
				hostFile=null;
				so.setString("DefaultHostPath", null);
			}

			if (!logDir || !logDir.isDirectory)
			{
				logDir=File.applicationDirectory;
			}

			appModel.hostFile=hostFile;
			appModel.logDir=logDir;

			so.setString("DefaultLogPath", logDir.nativePath);

			appModel.appName=appXml.ns::name.toString();
			appModel.appVersionLabel=appXml.ns::versionLabel[0].toString();
			navModel.MAIN_CURRENT_SATAE=MainCurrentState.FIRST;

			trace(Global.classInfo);
		}

		[EventHandler(event="FileEventEX.HOSTLIST_FILE_BROWSE")]
		public function browseHostList(event:FileEventEX):void
		{
			appModel.hostFile=(appModel.hostFile) ? appModel.hostFile : File.applicationDirectory;
			appModel.hostFile.addEventListener(Event.SELECT, onSelectHostList);
			appModel.hostFile.browseForOpen("Select Host List", appModel.hostFileTypeFilter);
		}

		protected function onSelectHostList(event:Event):void
		{
			if (appModel.hostFile && appModel.hostFile.exists && !appModel.hostFile.isDirectory)
			{
				so.setString("DefaultHostPath", appModel.hostFile.nativePath);
				getHostList(appModel.hostFile);
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
			
			if (data && StringUtil.trim(data).length > 0 && xml is XML)
			{
				var fileStream:FileStream=new FileStream();
				var vo:HostVo=null;
				var hostList:ArrayCollection = new ArrayCollection;
				
				commandFile = "command.sh";
//				commands.push("en");
//				commands.push("sh clock");
//				commands.push("ter len 0");
//				commands.push("sh ver | in IOS");
//				commands.push("sh ver | in WS");
//				commands.push("sh run");
//				commands.push("sh ver | in memory");
//				commands.push("sh crypto key mypubkey rsa | in Key name");
				
				for (var i:int=0; i < xml.sheet[0].row.length(); i++)
				{
					var row:Object= xml.sheet[0].row[i];
					
					if(row && row.col && row.col[0].toString() && row.col[1].toString() && row.col[2].toString())
					{
						vo=new HostVo();
						vo.no=i + 1;
						vo.hostName=row.col[0].toString();
						vo.loginId=row.col[1].toString();
						vo.password=row.col[2].toString();
						vo.port ||= 22;
						vo.commandFile = commandFile;
						
						Global.log(row.toString());
						hostList.addItem(vo);
					}
				}
				appModel.hostList = hostList;
			}

			if(excel2xml)
			{
				excel2xml.dispose();
				excel2xml = null;
			}
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
			
			Alert.show(data);
			trace("Got: ", data);
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
				
				currentItem.label = ssh.output;
				currentItem.onLine = !!(currentItem.label);

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