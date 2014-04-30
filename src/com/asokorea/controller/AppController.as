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
	import com.asokorea.model.vo.UserVo;
	import com.asokorea.supportclass.NativeUpdater;
	import com.asokorea.util.DateUtil;
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
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.ReturnKeyLabel;
	import flash.utils.Dictionary;
	import flash.xml.XMLNode;
	
	import flashx.textLayout.events.DamageEvent;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.formatters.DateFormatter;
	import mx.utils.StringUtil;
	
	public class AppController
	{
		private var process:NativeProcess;
		
		[Inject]
		public var appModel:AppModel;
		
		[Inject]
		public var navModel:NavigationModel;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		[PostConstruct]
		public function init():void
		{
			var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXml.namespace();
			
			appModel.appName = appXml.ns::name.toString();
			appModel.appVersionLabel = appXml.ns::versionLabel[0].toString();
			appModel.updater = new NativeUpdater();
			appModel.updater.init();
			appModel.settingsVo = new SettingsVo();
			appModel.settingsVo.save();
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_FIRST;
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
				logDir = Global.DEFAULT_LOG_DIR;
			}
			
			logDir.browseForDirectory("Select Log Directory");
			logDir.addEventListener(Event.SELECT, function(evt:Event):void{
				appModel.selectedTaskVo.logPath = logDir.nativePath;
				appModel.selectedTaskVo.save();
			});
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
				getHostList(appModel.selectedHostListFile);				
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
			appModel.selectedTaskVo.save();
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

			appModel.multiSSH = new MultiSSH();
			appModel.multiSSH.addEventListener(MultiSSHEvent.CONNECTED, onSSHConnected);
			appModel.multiSSH.addEventListener(MultiSSHEvent.COMPELETE, onSSHCompelete);
			appModel.multiSSH.addEventListener(MultiSSHEvent.MESSAGE, onSSHMessage);
			appModel.multiSSH.addEventListener(MultiSSHEvent.LOGIN_FAIL, onSSHError);
			appModel.multiSSH.addEventListener(MultiSSHEvent.TIMEOUT, onSSHError);
			appModel.multiSSH.addEventListener(MultiSSHEvent.SSH_ERROR, onSSHError);
			appModel.multiSSH.addEventListener(MultiSSHEvent.EXCEPTION, onSSHError);
			appModel.multiSSH.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			appModel.multiSSH.addEventListener("notFoundJava", noJavaHandler);
			appModel.multiSSH.execute(event.taskVo);
		}
		
		protected function onSSHConnected(event:MultiSSHEvent):void
		{
			var eventHostVo:HostVo = event.hostVo;
			var hostVo:HostVo = appModel.selectedTaskVo.getHostVo(eventHostVo.ip);
			var result:String = "";
			
			if(eventHostVo && eventHostVo.ip && hostVo is HostVo)
			{
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
			var eventHostVo:HostVo = event.hostVo;
			var hostVo:HostVo = appModel.selectedTaskVo.getHostVo(eventHostVo.ip);
			var result:String = "";
			
			if(eventHostVo && eventHostVo.ip && hostVo is HostVo && eventHostVo.logFile is File && eventHostVo.logFile.exists)
			{
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
			var hostVo:HostVo = event.hostVo;
			
			if(hostVo is HostVo)
			{
				event.hostVo.output ||= "";
				event.hostVo.output += StringUtil.trim(event.data) + "\n";
			}
			appModel.standardOutput = StringUtil.trim(event.data) + "\n";			
		}
		
		protected function onSSHError(event:MultiSSHEvent):void
		{
			var hostVo:HostVo = event.hostVo;
			
			if(hostVo is HostVo)
			{
				hostVo = appModel.selectedTaskVo.getHostVo(hostVo.ip);
				hostVo.output ||= "";
				hostVo.output += StringUtil.trim(event.data) + "\n";
			}
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
				var selectdHostVo:HostVo = event.hostVo;
				
				if(selectdHostVo.isDefault)
				{
					setDefaultHostVo(selectdHostVo);
				}else{
					setDefaultHostVo(null);
				}
			}
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler("analysisUsers")]
		public function analysisUsers():void
		{
			var standardHostVo:HostVo = getMaxUserCountHost();
			setDefaultHostVo(standardHostVo);
		}
		
		private function getMaxUserCountHost():HostVo
		{
			var maxCount:int = 0;
			var standardHostVo:HostVo;
			var hosts:Array;
			
			for each (var hostVo:HostVo in appModel.selectedTaskVo.hostList) 
			{
				hostVo.isDefault = false;
				hosts = getSameTypeHosts(hostVo);
				
				if(hosts && hosts.length > 1)
				{
					if(hosts.length > maxCount)
					{
						maxCount = hosts.length;
						standardHostVo = hostVo;
					}
					
					if(maxCount > (appModel.selectedTaskVo.hostList.length / 2))
					{
						break;
					}
				}
			}
			
			return standardHostVo;
		}
		
		private function setDefaultHostVo(hostVo:HostVo):void
		{
			appModel.totalUsersCount = 0;
			appModel.standardUserCount = 0;
			appModel.standardUserList = null;
			appModel.standardUserMap = null;
			
			var item:HostVo;
			
			if(hostVo)
			{
				if(hostVo.isComplete)
				{
					hostVo.isDefault = true;
					appModel.standardUserList = hostVo.userList;
					appModel.standardUserMap = hostVo.userMap;
				}else
				{
					hostVo.isDefault = false;
				}
				
				for each (item in appModel.selectedTaskVo.hostList) 
				{
					item.isDefault = false;
					
					if(item.isComplete)
					{
						appModel.totalUsersCount ++;
						if(item.equalsToDefaultUser(hostVo))
						{
							item.isDefault = true;
							appModel.standardUserCount ++;
						}
					}
				}
			}else
			{
				for each (item in appModel.selectedTaskVo.hostList) 
				{
					item.isDefault = false;
				}
			}
		}
		
		private function getSameTypeHosts(hostVo:HostVo):Array
		{
			var result:Array = [];
			
			if(hostVo && hostVo.isComplete)
			{
				result = [hostVo];
				
				for each (var item:HostVo in appModel.selectedTaskVo.hostList) 
				{
					if(item.isComplete && item != hostVo && item.equalsToDefaultUser(hostVo))
					{
						result.push(item);
					}
				}
			}
			
			return result;
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
			
			if(appModel.successHostCount > 0)
			{
				analysisUsers();
			}else
			{
				appModel.userTypeList = null;
				appModel.standardUserList = null;
				appModel.standardUserMap = null;
				appModel.standardUserCount = 0;
				appModel.totalUsersCount = 0;
			}
			
			appModel.failHostCount = appModel.hostCount - appModel.successHostCount;
			appModel.standardOutput = "Task Completed!";
			Alert.show("Task Completed!");
			navModel.MAIN_CURRENT_SATAE = NavigationModel.MAIN_OPEN;
		}
		
		[EventHandler("exportExcel")]
		public function exportExcel():void
		{
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = "YYYY-MM-DD HH:NN:SS"
			var createDate:Date = new Date();
			var xml:XML = 
			<report>
				<summary>44
					<total>{appModel.hostCount}</total>
					<success>{appModel.successHostCount}</success>
				</summary>
				<createDate>{dateFormatter.format(createDate)}</createDate>
				<createTimeStamp>{createDate.time}</createTimeStamp>
				<hosts>
				</hosts>
			</report>;
			
			for each (var hostVo:HostVo in appModel.selectedTaskVo.hostList) 
			{
				var userCount:int = (hostVo.isComplete && hostVo.userList) ? hostVo.userList.length : 0; 
				var errorLog:String = (hostVo.isComplete && hostVo.isConnected) ? "" : hostVo.output; 
				
				var host:XML = 
				<host>
					<ip>{hostVo.ip}</ip>
					<hostName>{hostVo.hostName}</hostName>
					<isComplete>{hostVo.isConnected}</isComplete>
					<userCount>{userCount}</userCount>
					<errorLog>{errorLog}</errorLog>
				</host>;
				
				xml..hosts.appendChild(host);
			}
			
			var file:File = appModel.selectedTaskVo.taskBaseDir.resolvePath("report.xml");
			Global.saveXml(xml, file);
			file.openWithDefaultApplication();
		}
		
		[EventHandler("openUsersReport")]
		public function openUsersReport():void
		{
			var file:File = appModel.selectedTaskVo.taskBaseDir.resolvePath("report.txt");
			var fileStream:FileStream = new FileStream();
			var br:String = File.lineEnding;
			var standardUserList:ArrayCollection = appModel.standardUserList;
			var standardUserMap:Dictionary = appModel.standardUserMap;;
			var reportFormat:String = "";
			
			reportFormat += "## Users Report ##" + br;
			reportFormat += br;
			reportFormat += "[Task result]" + br;
			reportFormat += "Total Host Count : " + appModel.selectedTaskVo.hostList.length + br;
			reportFormat += "Success Host Count : " + appModel.successHostCount + br;
			reportFormat += "Fail Host Count : " + (appModel.selectedTaskVo.hostList.length - appModel.successHostCount) + br;
			reportFormat += br;
			reportFormat += "[Task result]" + br;
			reportFormat += "Total Host Count : " + appModel.selectedTaskVo.hostList.length + br;
			reportFormat += "Success Host Count : " + appModel.successHostCount + br;
			reportFormat += "Fail Host Count : " + (appModel.selectedTaskVo.hostList.length - appModel.successHostCount) + br;
			reportFormat += br;
			reportFormat += "[User list analysis result]" + br;
			reportFormat += "Total Available user list Count : " + appModel.totalUsersCount + br;
			reportFormat += "Standard user list Count : " + appModel.standardUserCount + br;
			reportFormat += "Exception user list Count : " + (appModel.totalUsersCount - appModel.standardUserCount) + br;
			reportFormat += br;
			reportFormat += "[Standard user list]" + br;
			reportFormat += "User count : " + appModel.standardUserList.length + br;
			reportFormat += br;

			for each (var standardUserVo:UserVo in appModel.standardUserList) 
			{
				reportFormat += getUserString(standardUserVo) + br;
			}

			var idx:int = 0;
			
			for each (var hostVo:HostVo in appModel.selectedTaskVo.hostList) 
			{
				if(!hostVo.isDefault && hostVo.userList && hostVo.userList.length > 0)
				{
					idx ++;
					reportFormat += br;
					reportFormat += "[Exception user list #" + idx + "]" + br;
					reportFormat += "IP : " + hostVo.ip + br;
					reportFormat += "Host Name : " + hostVo.hostName + br;
					reportFormat += "User count : " + hostVo.userList.length + br;
					reportFormat += br;
					
					var adds:Array = [];
					var subs:Array = [];
					var diffs:Array = [];
					
					for each (var userVo:UserVo in hostVo.userList) 
					{
						var item:UserVo = standardUserMap[userVo.userName] as UserVo;
						
						if(!(item is UserVo))
						{
							adds.push(reportFormat += "+ " + getUserString(userVo) + br);
						}else {
							var userName:String = item.userName;
							var privilege:int = item.privilege;
							var secret:int = item.secret;
							var hash:String = (item.hash) ? item.hash : "";

							if(userVo.userName == userName && (userVo.privilege != privilege || userVo.secret != secret))
							{
								diffs.push(reportFormat += "* " + getUserString(userVo) + br);
							}
						}
					}
					
					for each (var sUser:UserVo in appModel.standardUserList) 
					{
						if(!(hostVo.userMap[sUser.userName] is UserVo))
						{
							diffs.push(reportFormat += "- " + getUserString(sUser) + br);
						}
					}
				}
			}
			
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(reportFormat);
			file.openWithDefaultApplication();
			fileStream.close();
			fileStream = null;
			file = null;
		}
		
		private function getUserString(userVo:UserVo):String
		{
			var result:String = "";
			
			if(userVo.secret && userVo.hash)
			{
				result += "username " + userVo.userName;
				result += " privilege " + userVo.privilege;
				result += " secret " + userVo.secret;
				result += " hash " + userVo.hash;
			}else{
				result += "username " + userVo.userName;
				result += " password " + userVo.privilege;
				result += " hash " + userVo.hash;
			}
			
			return result;
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