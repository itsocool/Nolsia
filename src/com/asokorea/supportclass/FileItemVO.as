package com.asokorea.supportclass
{
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	
	public class FileItemVO
	{
		private var _host:String;
		private var _no:uint;
		private var _file:File;
		private var _fileName:String;
		private var _userList:ArrayCollection;
		private var _readOK:Boolean;
		
		[Bindable]
		public var firstLine:String;
		
		public function FileItemVO(no:uint, file:File)
		{
			this._no = no;
			this._file = file;
			this._fileName = file.name;
			this._readOK = false;
		}
		
		[Bindable]
		public function get host():String
		{
			return _host;
		}
		
		public function set host(value:String):void
		{
			_host = value;
		}
		
		public function get file():File
		{
			return _file;
		}
		
		public function get no():uint
		{
			return _no;
		}
		
		public function get fileName():String
		{
			return _fileName;
		}
		
		[Bindable]
		public function get userList():ArrayCollection
		{
			return _userList;
		}
		
		public function set userList(value:ArrayCollection):void
		{
			_userList = value;
			
			if(value is ArrayCollection && value.length > 0)
			{
				firstLine = value[0] as String;
			}else
			{
				firstLine = "Not Found String";
			}
		}
		
		public function get readOK():Boolean
		{
			return _readOK;
		}
		
		public function set readOK(value:Boolean):void
		{
			_readOK = value;
		}
		
	}
}