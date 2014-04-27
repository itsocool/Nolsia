package com.asokorea.model.vo
{
	import mx.collections.ArrayCollection;

	[Bindable]
	public class SshVo
	{
		public var user:String;
		public var password:String;
		public var timeout:int;
		public var autoExit:Boolean;
		public var maxConnection:int;
		public var commands:ArrayCollection;
		
		public function load(xml:XML):void
		{
			if(xml)
			{
				user = xml.user;
				password = xml.password;
				timeout = xml.timeout;
				maxConnection = xml.maxConnection;
				autoExit = xml.autoExit;
				commands = new ArrayCollection();
				
				var commandList:XMLList = xml..command;
				
				for each (var command:XML in commandList) 
				{
					commands.addItem(command.toString());
				}
			}
		}
	}
}