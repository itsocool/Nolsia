package com.asokorea.util
{
	import com.asokorea.model.AppModel;
	import com.asokorea.model.enum.ExternalCommandType;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.xml.XMLDocument;

	[Event(name="complete", type="flash.events.Event")]
	[Event(name="standardErrorClose", type="flash.events.Event")]
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class Xml2Excel extends NativeProcess
	{
		static public const NOT_FOUND_JAVA:String = "Not found java";
		
		public var cmdFile:File;
		public var xmlFile:File;
		public var xml:XMLDocument;
		public var consoleEncoding:String = "EUC-KR";
		
		private var _output:String = "";
		private var _error:String = "";

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

		public function Xml2Excel()
		{
			cmdFile = File.applicationDirectory.resolvePath("windows.cmd");
			xmlFile = xmlFile;
		}
		
		public function execute(xmlFile:File, exportFile:File):void
		{
			this.xmlFile = xmlFile;
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var processArgs:Vector.<String>=new Vector.<String>();
			var file:File =	Global.TEMPLETE_DIR.resolvePath("report.xls");
			
			if(file && file.exists && !file.isDirectory)
			{
				file.copyTo(exportFile, true);
				processArgs.push(ExternalCommandType.EXPORT);
				processArgs.push(xmlFile.nativePath.replace(/ /g,"[_]"));
				processArgs.push(exportFile.nativePath.replace(/ /g,"[_]"));
				
				nativeProcessStartupInfo.executable = cmdFile;
				nativeProcessStartupInfo.arguments = processArgs;
				
				addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
				addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
				addEventListener(NativeProcessExitEvent.EXIT, onExit);
				start(nativeProcessStartupInfo);
			}
		}
		
		protected function onOutputData(event:ProgressEvent):void
		{
			if(running){				
				
				if(standardOutput && standardOutput.bytesAvailable)
				{
					_output += standardOutput.readMultiByte(standardOutput.bytesAvailable,consoleEncoding);
				}
				
				if(_output && _output.indexOf(NOT_FOUND_JAVA) > -1)
				{
					dispatchEvent(new Event("notFoundJava"));
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
			dispatchEvent(new Event(Event.COMPLETE, true));
		}
		
		protected function onIOErrorData(event:IOErrorEvent):void
		{
			dispatchEvent(new Event(Event.STANDARD_ERROR_CLOSE));
		}
		
		public function dispose():void
		{
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			
			if(cmdFile)	cmdFile = null;
			if(xmlFile) xmlFile = null;
			if(running) exit(true);
			_output = null;
			_error = null;
		}
	}
}