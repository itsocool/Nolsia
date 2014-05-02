package com.asokorea.util
{
	import com.asokorea.model.enum.ExternalCommandType;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.xml.XMLDocument;

	[Event(name="complete", type="flash.events.Event")]
	[Event(name="excelError", type="flash.events.Event")]
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class ExcelUtil extends NativeProcess
	{
		static public const NOT_FOUND_JAVA:String = "Not found java";
		static public var hostFileTypeFilter:Array = [
			new FileFilter("Excel File (*.xls;*.xlsx)", "*.xls;*.xlsx")
			, new FileFilter("Text File (*.txt;*.xml;*.json,*.csv)", "*.txt;*.xml;*.json,*.csv")
			, new FileFilter("All File", "*.*")
		];
		
		public var cmdFile:File;
		private var _xmlFile:File;
		private var _excelFile:File;
		public var xml:XML;
		public var consoleEncoding:String = "EUC-KR";
		
		private var _output:String = "";
		private var _error:String = "";

		public function get excelFile():File
		{
			return _excelFile;
		}

		public function get xmlFile():File
		{
			return _xmlFile;
		}

		[Bindable]
		public function get output():String
		{
			return _output;
		}

		public function set output(value:String):void
		{
			_output = value;
		}

		[Bindable]
		public function get error():String
		{
			return _error;
		}

		public function set error(value:String):void
		{
			_error = value;
		}

		public function ExcelUtil()
		{
			this.cmdFile = File.applicationDirectory.resolvePath("windows.cmd");
		}
		
		public function importExcel(excelFile:File, xmlFile:File = null):void
		{
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var processArgs:Vector.<String>=new Vector.<String>();

			_excelFile = excelFile;
			_xmlFile = xmlFile;
			
			processArgs.push(ExternalCommandType.IMPORT);
			processArgs.push(excelFile.nativePath.replace(/ /g,"[_]"));
			
			nativeProcessStartupInfo.executable = cmdFile;
			nativeProcessStartupInfo.arguments = processArgs;
			addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			addEventListener(NativeProcessExitEvent.EXIT, onExit);
			start(nativeProcessStartupInfo);
		}
		
		public function exportExcel(xmlFile:File, excelFile:File):void
		{
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var processArgs:Vector.<String>=new Vector.<String>();

			_excelFile = excelFile;
			_xmlFile = xmlFile;
			
			processArgs.push(ExternalCommandType.EXPORT);
			processArgs.push(xmlFile.nativePath.replace(/ /g,"[_]"));
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
			if(running){				
				
				if(standardOutput && standardOutput.bytesAvailable)
				{
					_output += standardOutput.readMultiByte(standardOutput.bytesAvailable,consoleEncoding);
				}
			}
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			if(running){				
				if(standardError && standardError.bytesAvailable)
				{
					_error += standardError.readMultiByte(standardError.bytesAvailable,consoleEncoding);
				}
				
				if(_error && _error.indexOf(NOT_FOUND_JAVA) > -1)
				{
					dispatchEvent(new Event("notFoundJava"));
				}
			}			
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			xml = XML(_output);
			
			if(xmlFile)
			{
				Global.saveXml(xml, xmlFile);
			}
			
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			dispatchEvent(new Event(Event.COMPLETE, true));
		}
		
		protected function onIOErrorData(event:IOErrorEvent):void
		{
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			dispatchEvent(new Event(Event.STANDARD_ERROR_CLOSE));
		}
		
		public function dispose():void
		{
			_output = null;
			_error = null;

			if(cmdFile)	cmdFile = null;
			if(_xmlFile) _xmlFile = null;
			if(_excelFile) _excelFile = null;
			if(xml) xml = null;
			if(running) exit(true);
		}
	}
}