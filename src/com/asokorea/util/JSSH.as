package com.asokorea.util
{
	import com.asokorea.event.SSHEvent;
	import com.asokorea.model.vo.HostVo;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	[Event(name="init", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="standardErrorClose", type="flash.events.Event")]
	[Event(name="ouputData", type="flash.events.DataEvent")]
	[Event(name="errorData", type="flash.events.DataEvent")]
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class JSSH extends EventDispatcher
	{
		static public const NOT_FOUND_JAVA:String = "[Not found java]";
		
		public var cmdFile:File;
		public var consoleEncoding:String = "EUC-KR";
		
		private var process:NativeProcess;
		private var _output:String = "";
		private var _error:String = "";
		private var vo:HostVo = null;

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

		public function init(vo:HostVo):void
		{
			this.vo = vo;
			this.cmdFile = File.applicationDirectory.resolvePath("./JSSH.cmd");
			dispatchEvent(new Event(Event.INIT, true));
		}
		
		public function execute():void
		{
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var processArgs:Vector.<String>=new Vector.<String>();
			processArgs.push(vo.ip);
			processArgs.push(vo.user);
			processArgs.push(vo.password);
			processArgs.push(vo.port.toString());
			processArgs.push(vo.commandFile);
			
			nativeProcessStartupInfo.executable = cmdFile;
			nativeProcessStartupInfo.arguments=processArgs;
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
				
				var str:String = "";
				
				if(process.standardOutput && process.standardOutput.bytesAvailable)
				{
					str = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,consoleEncoding);
					_output += str;
					trace("OUTPUT : " + str);
					dispatchEvent(new DataEvent("outputData", true, true, str));
				}
			}
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			if(process && process.running){
				
				var str:String = "";
				
				if(process.standardError && process.standardError.bytesAvailable)
				{
					str = process.standardError.readMultiByte(process.standardError.bytesAvailable,consoleEncoding);
					_error += str;
					trace("ERROR : " + str);
					dispatchEvent(new DataEvent("errorData", true, true, str));
				}
				
				if(_error && _error.indexOf(NOT_FOUND_JAVA) > -1)
				{
					dispatchEvent(new Event("notFoundJava"));
				}
			}			
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			trace("last output = ",output);
			trace("last error = ",error);
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
			if(process){
				if(process.running) process.exit(true);
				process = null;
			}
			_output = null;
			_error = null;
		}
	}
}