package com.asokorea.util
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	[Event(name="complete", type="flash.events.Event")]
	public class Shell extends NativeProcess
	{
		private var consoleEncoding:String = "EUC-KR";
		private var cmdFile:File;
		private var _output:String = "";
		private var _error:String = "";
		private var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		private var processArgs:Vector.<String>=new Vector.<String>();

		public function execute(account:String):void
		{
			nativeProcessStartupInfo.executable = File.applicationDirectory.resolvePath("windows.cmd");
			processArgs.push("shell");
			processArgs.push(account);
			nativeProcessStartupInfo.arguments = processArgs;
			addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			addEventListener(NativeProcessExitEvent.EXIT, onExit);
			start(nativeProcessStartupInfo);
		}
		
		protected function onOutputData(event:ProgressEvent):void
		{
			if(running && standardOutput && standardOutput.bytesAvailable)
			{
				_output += standardOutput.readMultiByte(standardOutput.bytesAvailable,consoleEncoding);
			}
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			if(running && standardError && standardError.bytesAvailable)
			{
				_error += standardError.readMultiByte(standardError.bytesAvailable,consoleEncoding);
			}
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);
			dispatchEvent(new Event(Event.COMPLETE, true));
		}
		
		public function dispose():void
		{
			_output = null;
			_error = null;
			if(cmdFile)	cmdFile = null;
			if(running) exit(true);
		}
	}
}