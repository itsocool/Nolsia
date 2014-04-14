package com.asokorea.util
{
	import flash.system.Capabilities;
	
	import mx.controls.Alert;

	public final class Global
	{
		public static function get classInfo():ClassInfo
		{
			return getClassInfo(3);
		}
		
		protected static function getClassInfo(level:int = 3):ClassInfo
		{
			var tmp:Array = new Error().getStackTrace().split("\n");
			var str:String = "";
			var headStr:String = "";
			var tailStr:String = "";
			var packageName:String = "";
			var className:String = "";
			var method:String = "";
			var fileName:String = "";
			var lineNumber:String = "";
			
			if(tmp is Array)
			{
				str = tmp[level];
				headStr = str.match(/[a-zA-Z0-9_$\.]+::[a-zA-Z0-9_$\.]+\/(get |set )*[a-zA-Z0-9_$\.]+\(\)/)[0];
				tailStr = str.match(/[a-zA-Z0-9_$]+\.[a-zA-Z0-9_$]+:[0-9]+/)[0];
				
				if(headStr && tailStr)
				{
					packageName = headStr.split("::")[0];
					className = String(headStr.split("::")[1]).split("/")[0];
					method = String(headStr.split("::")[1]).split("/")[1];
					fileName = tailStr.split(":")[0];
					lineNumber = tailStr.split(":")[1];
				}
			}
			
			return new ClassInfo(className, method, fileName, lineNumber, packageName);
		}
		
		public static function showError(msg: String):void
		{		
			Alert.show( msg, "ERROR" );
		}
		
		public static function log(message:String = null):void
		{
			var classInfo:ClassInfo = null;
			var className:String = "";
			var method:String = "";
			
			message ||= "AUTO_LOG : "

			if(Capabilities.isDebugger)
			{
				classInfo = getClassInfo();
				trace(message, classInfo.className, classInfo.method);
			}else{
				trace(message);
			}
		}
	}
	
}

class ClassInfo
{
	public var className:String;
	public var method:String;
	public var fileName:String;
	public var lineNumber:String;
	public var packageName:String;
	
	public function ClassInfo(className:String, method:String, fileName:String = null, lineNumber:String = null, packageName:String = null)
	{
		this.className = className || "";
		this.method = method || "";
		this.fileName = fileName || "";
		this.lineNumber = lineNumber || "";
		this.packageName = packageName || "";
	}
	
	public function toString():String
	{
		return packageName + "." + className + "::" + method + " " + fileName + ":" + lineNumber;
	}
}