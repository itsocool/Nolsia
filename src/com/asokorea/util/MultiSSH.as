package com.asokorea.util
{
	import com.asokorea.model.enum.ExternalCommandType;
	import com.asokorea.model.vo.TaskVo;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class MultiSSH extends NativeProcess
	{
		static public const NOT_FOUND_JAVA:String = "Not found java";
		
		private var cmdFile:File = File.applicationDirectory.resolvePath("windows.cmd");
		private var consoleEncoding:String = "EUC-KR";
		private var _output:String = "";
		private var _error:String = "";
		private var _totalOutput:String = "";
		private var _totalError:String = "";
		
		private var _sdt:Date;
		private var _edt:Date;
		private var _timeSpan:int = 0;

		public function execute(taskVo:TaskVo):void
		{
			_sdt = new Date();			
			
			if(taskVo is TaskVo)
			{
				var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				var processArgs:Vector.<String>=new Vector.<String>();
				
				processArgs.push(ExternalCommandType.SSH);
				processArgs.push(taskVo.nativePath.replace(/ /g,"[_]"));
				processArgs.push(taskVo.taskName);
				
				nativeProcessStartupInfo.executable = cmdFile;
				nativeProcessStartupInfo.arguments = processArgs;
				addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
				addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				addEventListener(NativeProcessExitEvent.EXIT, onExit);
				start(nativeProcessStartupInfo);
			}
		}
		
		protected function onExit(event:NativeProcessExitEvent):void
		{
			removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			removeEventListener(NativeProcessExitEvent.EXIT, onExit);

			_edt = new Date();
			_timeSpan = int(_edt.time - _sdt.time);
		}
		
		protected function onOutputData(event:ProgressEvent):void
		{
			if(standardOutput && standardOutput.bytesAvailable)
			{
				var result:String = standardOutput.readMultiByte(standardOutput.bytesAvailable,consoleEncoding);
				_output = result;
				_totalOutput += _output;
			}
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			if(standardError && standardError.bytesAvailable)
			{
				var result:String = standardError.readMultiByte(standardError.bytesAvailable,consoleEncoding);
				_error = result;
				_totalError += _error;
			}
			
			if(_error && _error.indexOf(NOT_FOUND_JAVA) > -1)
			{
				dispatchEvent(new Event("notFoundJava"));
			}
		}
		
		public function dispose():void
		{
			closeInput();

			if(cmdFile)
			{
				cmdFile = null;
			}

			_output = null;
			_error = null;
			_totalError = null;
			_totalOutput = null

			exit(true);
		}
		
		public function get timeSpan():int
		{
			return _timeSpan;
		}
		
		public function get edt():Date
		{
			return _edt;
		}
		
		public function get sdt():Date
		{
			return _sdt;
		}
		
		public function get totalError():String
		{
			return _totalError;
		}
		
		public function get totalOutput():String
		{
			return _totalOutput;
		}
		
		[Bindable]
		public function get output():String
		{
			return _output;
		}
		
		protected function set output(value:String):void
		{
			_output = value;
			_totalOutput += value;
		}
		
		[Bindable]
		public function get error():String
		{
			return _error;
		}
		
		protected function set error(value:String):void
		{
			_error = value;
			_totalError += value;
		}
	}
}