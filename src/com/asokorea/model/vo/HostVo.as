package com.asokorea.model.vo
{
	import com.asokorea.util.Global;
	
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.utils.StringUtil;

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
		public var type:String;
		
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
					
					matches = str.match(/username .+ (privilege [0-9]+ secret [0-9]+ .+|password [0-9]+ [0-9]+)/g);
					
					if(matches)
					{
						userList = new ArrayCollection();
						userMap = new Dictionary();
						
						for (var i:int = 0; i < matches.length; i++) 
						{
							var user:UserVo = new UserVo();
							var arr:Array = matches[i].split(" ");
							user.no = i + 1;
							user.userName = (arr[1]) ? StringUtil.trim(arr[1]) : null;
							user.privilege = isNaN(parseInt(arr[3])) ? NaN : parseInt(arr[3]);
							
							if(arr.length > 5)
							{
								user.secret = isNaN(parseInt(arr[5])) ? NaN : parseInt(arr[5]);
								user.hash =(arr[6]) ? StringUtil.trim(arr[6]) : null;
							}
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
			
			if(defaultHostVo && defaultHostVo.userList && defaultHostVo.userList.length &&
				userList && userList.length && defaultHostVo.userList.length == userList.length)
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
