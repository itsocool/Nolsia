package com.asokorea.util
{
	import avmplus.USE_ITRAITS;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.system.System;
	import flash.xml.XMLDocument;
	
	import mx.controls.Alert;

	[Event(name="init", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="standardErrorClose", type="flash.events.Event")]
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class Excel2Xml extends EventDispatcher
	{
		static public const NOT_FOUND_JAVA:String = "[Not found java]";
		static public var hostFileTypeFilter:Array = [
			new FileFilter("Excel File (*.xls;*.xlsx)", "*.xls;*.xlsx")
			, new FileFilter("Text File (*.txt;*.xml;*.json,*.csv)", "*.txt;*.xml;*.json,*.csv")
			, new FileFilter("All File", "*.*")
		];
		
		public var cmdFile:File;
		public var excelFile:File;
		public var xml:XMLDocument;
		public var consoleEncoding:String = "EUC-KR";
		
		private var process:NativeProcess;
		private var _output:String = "";
		private var _error:String = "";
		private var saveXml:Boolean = false;
		private var useJar:Boolean = false;

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

		public function init(excelFile:File, useJar:Boolean = true):void
		{
			this.useJar = useJar;
			this.cmdFile = File.applicationDirectory.resolvePath("Excel2Xml.cmd");
			this.excelFile = excelFile;
			dispatchEvent(new Event(Event.INIT, true));
		}
		
		public function convertXML(saveXml:Boolean = false):void
		{
			this.saveXml = saveXml;
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var processArgs:Vector.<String>=new Vector.<String>();

			processArgs.push(excelFile.nativePath.replace(/ /g,"[_]"));
			if(saveXml)
			{
				processArgs.push("-f");
			}
			
			if(!useJar)
			{
				processArgs.push("-exe");
			}
			
			nativeProcessStartupInfo.executable = cmdFile;
			nativeProcessStartupInfo.arguments = processArgs;
			process = new NativeProcess();
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.start(nativeProcessStartupInfo);
		}
		
		protected function onOutputData(event:ProgressEvent):void
		{
			if(process && process.running){				
				
				if(process.standardOutput && process.standardOutput.bytesAvailable)
				{
					_output += process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,consoleEncoding);
				}
				
				if(_output && _output.indexOf(NOT_FOUND_JAVA) > -1)
				{
					dispatchEvent(new Event("notFoundJava"));
				}
			}
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			if(process && process.running){				
				if(process.standardError && process.standardError.bytesAvailable)
				{
					_error += process.standardError.readMultiByte(process.standardError.bytesAvailable,consoleEncoding);
				}
				
				if(_error && _error.indexOf(NOT_FOUND_JAVA) > -1)
				{
					dispatchEvent(new Event("notFoundJava"));
				}
			}			
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			xml = new XMLDocument(_output);
			process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			process.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			dispatchEvent(new Event(Event.COMPLETE, true));
		}
		
		protected function onIOErrorData(event:IOErrorEvent):void
		{
			trace(event.errorID);
			process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOErrorData);
			process.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			dispatchEvent(new Event(Event.STANDARD_ERROR_CLOSE));
		}
		
		public function dispose():void
		{
			if(cmdFile)	cmdFile = null;
			if(excelFile) excelFile = null;
			if(xml) xml = null;
			if(process){
				if(process.running) process.exit(true);
				process = null;
			}
			_output = null;
			_error = null;
		}
		
	}
}