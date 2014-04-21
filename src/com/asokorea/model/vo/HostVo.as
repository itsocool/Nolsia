package com.asokorea.model.vo
{
	import com.asokorea.util.Global;
	
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;

	[Bindable]
	public class HostVo
	{
		public var no:uint;
		public var ip:String;
		public var hostName:String;
		public var user:String;
		public var password:String;
		public var port:int;
		public var isConnected:Boolean;
		public var isComplete:Boolean;
		public var isDefault:Boolean;
		public var userMap:Dictionary;
		private var _logFile:File;
		public var taskName:String;
		public var output:String;
		public var userList:ArrayCollection;
		
		public function get logFile():File
		{
			return _logFile;
		}

		public function set logFile(value:File):void
		{
			_logFile = value;
			
			isComplete = false;
			
			if(value is File)
			{
				var str:String = Global.readFile(value);
				var matches:Array = null;
				var hostName:String = null;
				
				if(str)
				{
					if((matches = str.match(/hostname .+/)) && matches.length > 0)
					{
						hostName = matches[0].toString().replace(/hostname /,"");
					}
					
					matches = str.match(/username .+/g);
					
					if(matches)
					{
						userList = new ArrayCollection();
						userMap = new Dictionary();
						
						for (var i:int = 0; i < matches.length; i++) 
						{
							var user:UserVo = new UserVo();
							var arr:Array = matches[i].split(" ");
							user.no = i + 1;
							user.userName = arr[1];
							user.privilege = arr[3];
							user.secret = arr[5]
							user.hash = arr[6];
							userMap[user.userName] = user;
							userList.addItem(user);
						}
					}
					
					isComplete = true;
				}
			}
		}

		public function equalsToDefaultUser(defaultHostVo:HostVo):Boolean
		{
			var result:Boolean = false;
			
			if(defaultHostVo && defaultHostVo.userList && defaultHostVo.userList.length > 0 &&
				defaultHostVo.userList.length == userList.length)
			{
				for each (var defaultUserVo:UserVo in defaultHostVo.userList) 
				{
					var targetUserVo:UserVo = userMap[defaultUserVo.userName] as UserVo;
					
					if(targetUserVo is UserVo && targetUserVo.privilege == defaultUserVo.privilege)
					{
						result = true;
						continue;						
					}else{
						result = false;
						break;
					}
				}
			}
			
			isDefault = result;
			return result;
		}
	}
}
