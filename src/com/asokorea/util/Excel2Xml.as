package com.asokorea.util
{
	import com.asokorea.model.enum.ExternalCommandType;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.Dictionary;
	import flash.xml.XMLDocument;
	
	import mx.collections.ArrayCollection;

	[Event(name="complete", type="flash.events.Event")]
	[Event(name="error", type="flash.events.Event")]
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class Excel2Xml extends NativeProcess
	{
		static public const NO_JAVA:String = "[Not found java]";
		static public const hostFileTypeFilter:Array=[new FileFilter("All File", "*.*"), new FileFilter("Excel File (*.xls;*.xlsx)", "*.xls;*.xlsx"), new FileFilter("Text File (*.txt;*.xml;*.json,*.csv)", "*.txt;*.xml;*.json,*.csv")];
		static public const fileFilters:Array=[new FileFilter("All File", "*.*"), new FileFilter("Log File (*.txt;*.log)", "*.txt;*.log")];
		
		private var cmdFile:File = File.applicationDirectory.resolvePath("windows.cmd");;
		private var consoleEncoding:String = "EUC-KR";
		
		private var _excelFile:File;
		private var _xmlFile:File;
		private var _xml:XML;
		private var output:String = "";
		private var error:String = "";
		
		private var _hostMap:Dictionary = new Dictionary();
		private var _hostList:ArrayCollection = new ArrayCollection();

		private var taskVo:TaskVo;
		
		[Bindable]
		public var hasHostList:Boolean;
		
		[Bindable]
		public var hostCount:int = 0;

		public function Excel2Xml(taskVo:TaskVo, excelFile:File, cmdFile:File = null):void
		{
			super();

			this.taskVo = taskVo;
			this.excelFile = excelFile;
			
			if(cmdFile && cmdFile.exists && !cmdFile.isDirectory)
			{
				this.cmdFile = cmdFile;	
			}
		}
		
		public function get xml():XML
		{
			return _xml;
		}

		[Bindable]
		public function get xmlFile():File
		{
			return _xmlFile;
		}

		public function set xmlFile(value:File):void
		{
			_xmlFile = value;
		}

		[Bindable]
		public function get excelFile():File
		{
			return _excelFile;
		}

		public function set excelFile(value:File):void
		{
			_excelFile = value;
		}

		[Bindable]
		public function get hostList():ArrayCollection
		{
			return _hostList;
		}

		public function set hostList(value:ArrayCollection):void
		{
			hasHostList = false;
			
			if(value && value.length > 0)
			{
				_hostMap = new Dictionary();
				
				for each (var hostVo:HostVo in value) 
				{
					_hostMap[hostVo.ip] = hostVo;						
				}
				
				hasHostList = true;
			}
			
			_hostList = value;
		}

		public function get hostMap():Dictionary
		{
			return _hostMap;
		}

		public function execute():void
		{
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var processArgs:Vector.<String> = new Vector.<String>();

			processArgs.push(ExternalCommandType.EXCEL);
			processArgs.push(excelFile.nativePath.replace(/ /g,"[_]"));
			
			nativeProcessStartupInfo.executable = cmdFile;
			nativeProcessStartupInfo.arguments = processArgs;
			
			addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			addEventListener(NativeProcessExitEvent.EXIT, onExit);
			start(nativeProcessStartupInfo);
		}
		
		protected function onOutputData(event:ProgressEvent):void
		{
			if(standardOutput && standardOutput.bytesAvailable)
			{
				output += standardOutput.readMultiByte(standardOutput.bytesAvailable,consoleEncoding);
			}
				
			if(output && output.indexOf(NO_JAVA) > -1)
			{
				dispatchEvent(new Event("notFoundJava"));
			}
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			if(standardError && standardError.bytesAvailable)
			{
				error += standardError.readMultiByte(standardError.bytesAvailable,consoleEncoding);
			}
			
			if(error && error.indexOf(NO_JAVA) > -1)
			{
				dispatchEvent(new Event("notFoundJava"));
			}
		}
		
		protected function onIOErrorData(event:IOErrorEvent):void
		{
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			dispatchEvent(new Event(Event.STANDARD_ERROR_CLOSE));
		}		
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);

			getHostList();
		}
		
		private function getHostList():void
		{
			_xml = new XML(output);

			if (_xml is XML)
			{
				xmlFile = File.userDirectory.resolvePath(taskVo.taskBaseDir + "/hostList.xml");
				Global.saveXml(_xml, xmlFile);
				
				var vo:HostVo = null;

				_hostMap = new Dictionary();
				_hostList = new ArrayCollection();
				
				for (var i:int=0; i < _xml.sheet[0].row.length(); i++)
				{
					var row:Object = _xml.sheet[0].row[i];
					
					if(row && row.col && row.col[0].toString() && row.col[1].toString() && row.col[2].toString())
					{
						vo = new HostVo();
						vo.no = i + 1;
						vo.ip = row.col[0].toString();
						
						if(!vo.ip || vo.ip.search(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/) < 0)
						{
							continue;
						}
						
						vo.user = row.col[1].toString() || taskVo.ssh.user;
						vo.password = row.col[2].toString() || taskVo.ssh.password;
						vo.port ||= 22;
						vo.taskName = taskVo.taskName;
						_hostMap[vo.ip] = vo;
						_hostList.addItem(vo);
					}
				}
				
				if(_hostList && _hostList.length > 0)
				{
					hasHostList = true;
					hostCount = _hostList.length;
				}else
				{
					hasHostList = false;
					hostCount = 0;
				}
			}

			dispatchEvent(new Event(Event.COMPLETE, true));
		}

		public function dispose():void
		{
			if(cmdFile)	cmdFile = null;
			if(excelFile) excelFile = null;
			if(_xml) _xml = null;

			output = null;
			error = null;
			
			exit(true);
		}
	}
}