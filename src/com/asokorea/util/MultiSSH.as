package com.asokorea.util
{
	import com.asokorea.event.MultiSSHEvent;
	import com.asokorea.model.enum.ExternalCommandType;
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.TaskVo;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	[Event(name="connected", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="compelete", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="message", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="loginFail", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="timeout", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="sshError", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="exception", type="com.asokorea.event.MultiSSHEvent")]
	[Event(name="notFoundJava", type="flash.events.Event")]
	public class MultiSSH extends NativeProcess
	{
		static private const NO_JAVA:String = "Not found java";
		
		private var cmdFile:File = File.applicationDirectory.resolvePath("windows.cmd");
		private var consoleEncoding:String = "EUC-KR";
		private var _output:String = "";
		private var _error:String = "";
		private var _totalOutput:String = "";
		private var _totalError:String = "";
		
		private var _sdt:Date;
		private var _edt:Date;
		private var _timeSpan:int = 0;
		private var _taskVo:TaskVo;
		private var _isExit:Boolean;
		
		public var runningIPList:ArrayCollection = new ArrayCollection(); 

		public function execute(taskVo:TaskVo):void
		{
			_taskVo = taskVo;
			_sdt = new Date();			
			
			if(taskVo is TaskVo)
			{
				var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				var processArgs:Vector.<String>=new Vector.<String>();
				
				processArgs.push(ExternalCommandType.SSH);
				processArgs.push(taskVo.configXmlPath.replace(/ /g,"[_]"));
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
			
			event.preventDefault();
			event.stopPropagation();
			
			var e:NativeProcessExitEvent = event.clone() as NativeProcessExitEvent;
			var i:int = 0;
			var id:uint = setInterval(function():void{
				
				if(i < 3)
				{
					if(runningIPList is ArrayCollection && runningIPList.length > 0)
					{
						i++;
						return;
					}
				}

				clearInterval(id);
				dispatchEvent(e);
			}, 1000); 
			
		}

		protected function onOutputData(event:ProgressEvent):void
		{
			if(standardOutput && standardOutput.bytesAvailable)
			{
				var result:String = standardOutput.readMultiByte(standardOutput.bytesAvailable,consoleEncoding);
				
				if(result && StringUtil.trim(result).length > 0)
				{
					var lines:Array = result.split(/\n|\r\n/);
					
					for each (var line:String in lines) 
					{
						if(line)
						{
							line = StringUtil.trim(line);
							onMessage(StringUtil.trim(line));
						}
					}
				}
			}
		}

		protected function onErrorData(event:ProgressEvent):void
		{
			if(standardError && standardError.bytesAvailable)
			{
				var result:String = standardError.readMultiByte(standardError.bytesAvailable,consoleEncoding);
			
				if(result && StringUtil.trim(result))
				{
					var lines:Array = result.split(/\n|\r\n/);
					
					for each (var line:String in lines) 
					{
						if(line)
						{
							line = StringUtil.trim(line);
							onMessage(StringUtil.trim(line));
						}
					}
				}
				
				if(result && result.indexOf(NO_JAVA) > -1)
				{
					dispatchEvent(new Event("notFoundJava"));
				}
			}
		}

		protected function onMessage(data:String):void
		{
			trace(data);
			
			var event:MultiSSHEvent = null;
			var matchers:Array = null;
			var json:Object = null;
			var hostVo:HostVo = null;
			var obj:Object = null;
			var result:String = null;
			var ip:String = null;
			var hostName:String = null;
			
			if(!data || !StringUtil.trim(data))
			{
				return;
			}
			
			try
			{
				matchers = data.match(/(CONNECTED|COMPLETE|LOGIN_FAIL|TIMEOUT|SSH_ERROR)/);
				
				if(!matchers || matchers.length < 1)
				{
					event = new MultiSSHEvent(MultiSSHEvent.MESSAGE, StringUtil.trim(data));
				}else
				{
					try
					{
						json = JSON.parse(data);
					} 
					catch(error:Error) 
					{
						event = new MultiSSHEvent(MultiSSHEvent.EXCEPTION, error.name + " : " + error.message);
					}
					
					hostVo = new HostVo();
					
					switch(matchers[0])
					{
						case "CONNECTED":
						{
							obj = json["CONNECTED"];
							ip = obj["ip"].toString();
							hostVo.ip = ip;
							hostVo.isConnected = true;
							result = StringUtil.substitute("[CONNECTED] {0}", ip);
							runningIPList.addItem(ip);
							event = new MultiSSHEvent(MultiSSHEvent.CONNECTED, result, hostVo);
							break;
						}

						case "COMPLETE":
						{
							obj = json["COMPLETE"];
							ip = obj["ip"].toString();
							hostName = obj["hostName"].toString();
							hostVo.ip = ip;
							hostVo.hostName = hostName;

							var logFile:File = new File(_taskVo.logPath).resolvePath(obj["fileName"].toString());
							
							if(logFile && logFile.exists && !logFile.isDirectory && logFile.size > 0)
							{
								hostVo.isComplete = true;
								hostVo.logFile = logFile;
								result = StringUtil.substitute("[COMPLETE] {0} {1} {2}", ip, hostName, logFile.name);
							}
							removeRunningIp(ip);
							event = new MultiSSHEvent(MultiSSHEvent.COMPELETE, result, hostVo);
							break;
						}
							
						case "LOGIN_FAIL":
						{
							obj = json["LOGIN_FAIL"];
							ip = obj["ip"].toString();
							hostVo.ip = ip;
							hostVo.isConnected = false;
							result = StringUtil.substitute("[LOGINFAIL] {0} : {1}", ip, obj["message"].toString());
							removeRunningIp(ip);
							event = new MultiSSHEvent(MultiSSHEvent.LOGIN_FAIL, result, hostVo);
							break;
						}
							
						case "TIMEOUT":
						{
							obj = json["TIMEOUT"];
							ip = obj["ip"].toString();
							hostVo.ip = ip;
							hostVo.isConnected = false;
							result = StringUtil.substitute("[TIMEOUT] {0} : {1}", ip, obj["message"].toString());
							removeRunningIp(ip);
							event = new MultiSSHEvent(MultiSSHEvent.TIMEOUT, result, hostVo);
							break;
						}
							
						case "SSH_ERROR":
						{
							obj = json["SSH_ERROR"];
							ip = obj["ip"].toString();
							hostVo.ip = ip;
							hostVo.isConnected = false;
							result = StringUtil.substitute("[SSH_ERROR] {0} : {1}", ip, obj["message"].toString());
							removeRunningIp(ip);
							event = new MultiSSHEvent(MultiSSHEvent.SSH_ERROR, result, hostVo);
							break;
						}
					}
				}
				
				dispatchEvent(event);
			} 
			catch(error:Error) 
			{
				if(hostVo && hostVo.ip)
				{
					ip = hostVo.ip;
					removeRunningIp(ip);
				}

				event = new MultiSSHEvent(MultiSSHEvent.EXCEPTION, error.name + " : " + error.message);
			}
		}
		
		public function removeRunningIp(ip:String):void
		{
			var idx:int = runningIPList.getItemIndex(ip);
			
			if(idx >= 0 && idx < runningIPList.length)
			{
				runningIPList.removeItemAt(idx);
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
	}
}