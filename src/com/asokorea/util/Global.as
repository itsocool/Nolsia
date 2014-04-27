package com.asokorea.util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
	
	import mx.controls.Alert;
	import mx.utils.StringUtil;

	public final class Global
	{
		public static const TEMPLETE_DIR:File = File.applicationDirectory.resolvePath("templete/task");
		public static const DEFAULT_TASK_NAME:String = "_default_";

		public static function get SETTING_FILE():File
		{
			var result:File = File.userDirectory.resolvePath("task");
			
			if(!result || !result.exists || !result.isDirectory)
			{
				TEMPLETE_DIR.copyTo(result);
			}

			result = result.resolvePath("settings.xml");
			
			if(!result || !result.exists)
			{
				var source:File = new File(TEMPLETE_DIR.nativePath + "/settings.xml");
				source.copyTo(result);
				result.load();
			}
			
			return result;
		}

		public static function get TASK_BASE_DIR():File
		{
			var result:File = File.userDirectory.resolvePath("task");
			
			if(!result || !result.exists || !result.isDirectory)
			{
				result.createDirectory();
			}
			
			return result;
		}

		public static function get DEFAULT_LOG_DIR():File
		{
			var result:File = File.userDirectory.resolvePath("logs");
			
			if(!result || !result.exists || !result.isDirectory)
			{
				result.createDirectory();
			}
			
			return result;
		}
		
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
		
		public static function cdata(data:String, tag:String):XML {
			var xml:XML = new XML("<" + tag + "/>");
			var result:XML = null;
			
			if(data && StringUtil.trim(data))
			{
				result = xml.appendChild(new XML("<![CDATA[" + data + "]]>"));
			}else
			{
				result = XML("<" + tag + "/>");
			}
			
			return result;
		}
		
		public static function readFile(file:File):String
		{
			var fileStream:FileStream = null;
			var result:String = null;
			
			try
			{
				fileStream = new FileStream();
				fileStream.open(file, FileMode.READ); 
				result = fileStream.readUTFBytes(fileStream.bytesAvailable);
				fileStream.close();
			} 
			catch(error:Error) 
			{
				if(fileStream)
				{
					fileStream.close();
				}
			}
			return result;
		}
		
		public static function readXml(file:File):XML
		{
			var result:XML = result = XML(readFile(file));
			return result;
		}
		
		public static function saveXml(xml:XML, file:File):void
		{
			var firstLine:String = '<?xml version="1.0" encoding="UTF-8"?>' + File.lineEnding;
			var fileStream:FileStream = null;
			var data:String = null;

			try
			{
				XML.prettyIndent = 2;
				data = firstLine + xml.toString();
				data = data.replace(/\n/g, File.lineEnding);
				fileStream = new FileStream();
				fileStream.open(file, FileMode.WRITE); 
				fileStream.writeUTFBytes(data);
				fileStream.close();
			} 
			catch(error:Error) 
			{
				if(fileStream)
				{
					fileStream.close();
				}
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