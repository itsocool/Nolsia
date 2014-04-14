package com.asokorea.supportclass
{
	import com.asokorea.event.FileReaderEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	[Event(name="directoryListing", type="flash.events.FileListEvent")]
	[Event(name="readFileList", type="com.asokorea.event.FileReaderEvent")]
	[Event(name="fileFiltering", type="com.asokorea.event.FileReaderEvent")]
	[Event(name="hostListSelect", type="com.asokorea.event.FileReaderEvent")]
	public class FileReader extends EventDispatcher
	{
		private var _file:File;
		private var _filter:IFilter;
		private var _allFilesInDrectory:Vector.<File>;
		private var _targetFileList:ArrayCollection;
		private var _readCount:uint;
		private var _isRunnig:Boolean;
		private var _fileStream:FileStream;
		
		[Bindable] public var selectedLogPath:String = null;
		[Bindable] public var allFilesCount:uint = 0;
		
		public function FileReader():void
		{
			trace("Create FileReader");
		}
		
		public function selectLogDir(file:File = null, filter:IFilter = null):void
		{
			_file = (file is File) ? file : new File();
			_file.addEventListener(Event.SELECT, onSelect);
			_filter = (filter is IFilter) ? filter : new DefaultFilter();
			_file.browseForDirectory("로그 폴더 선택");
			
			_fileStream = new FileStream();
			_fileStream.addEventListener(Event.COMPLETE, onComplete);
			_fileStream.addEventListener(ProgressEvent.PROGRESS, onProcess);
			_fileStream.addEventListener(IOErrorEvent.IO_ERROR, onError);
			trace("Selecting log directory");
		}
		
		public function readDirectory():void
		{
			_file.addEventListener(FileListEvent.DIRECTORY_LISTING, onListing);
			_file.getDirectoryListingAsync();
		}
		
		public function filtering(filter:IFilter = null):void
		{
			_filter = (filter is IFilter) ? filter : _filter;
			_targetFileList = _filter.filtering(_allFilesInDrectory);
		}
		
		protected function onSelect(event:Event):void
		{
			selectedLogPath = _file.nativePath;
			readDirectory();
		}
		
		protected function onListing(event:FileListEvent):void
		{
			_file.removeEventListener(FileListEvent.DIRECTORY_LISTING, onListing);
			_allFilesInDrectory = (event.files is Array) ? Vector.<File>(event.files) : null;
			filtering();
			
			dispatchEvent(new FileListEvent(FileListEvent.DIRECTORY_LISTING, false, false, event.files));
			trace("Create FileReader and listing complete");
		}
		
		public function start():void
		{
			readCount = 0;
			isRunnig = true;
			trace("start : " + readCount);
			
			var item:FileItemVO = _targetFileList[readCount] as FileItemVO;
			
			if(item is FileItemVO)
			{
				trace("open file : ", item.fileName);
				_fileStream.openAsync(item.file, FileMode.READ);
			}else{
				trace("Not found logs");
			}
			
		}
		
		protected function onError(event:IOErrorEvent):void
		{
			trace("io error");
			_fileStream.removeEventListener(Event.COMPLETE, onComplete);
			_fileStream.removeEventListener(ProgressEvent.PROGRESS, onProcess);
			_fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			trace(event.errorID);
			
			if(readCount >= _targetFileList.length)
			{
				_fileStream.close();
				_fileStream = null;
				Alert.show(readCount + " Log file(s) read complete.");
			}else{
				read(readCount);
				readCount ++;
			}
		}
		
		protected function onProcess(event:ProgressEvent):void
		{
			if(!isRunnig)
			{
				trace("stop");
				_fileStream.close();
				_fileStream.removeEventListener(Event.COMPLETE, onComplete);
				_fileStream.removeEventListener(ProgressEvent.PROGRESS, onProcess);
				_fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			}
		}
		
		protected function onComplete(event:Event):void
		{
			_fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			_fileStream.removeEventListener(ProgressEvent.PROGRESS, onProcess);
			_fileStream.removeEventListener(Event.COMPLETE, onComplete);
			
			if(readCount >= _targetFileList.length)
			{
				_fileStream.close();
				_fileStream = null;
				Alert.show(readCount + " Log file(s) read complete.");
			}else{
				read(readCount);
				readCount ++;
			}
		}
		
		private function read(index:uint):void
		{
			var item:FileItemVO = _targetFileList[readCount];
			
			if(item is FileItemVO)
			{
				trace("read file : ", index, item.fileName);
				
				var content:String = _fileStream.readUTFBytes(_fileStream.bytesAvailable);
				_fileStream.close();
				var hosts:Array = content.match(/^\s*hostname *[a-zA-Z0-9_\-\#]+/igm);
				
				if(hosts is Array && hosts.length > 0)
				{
					item.host = hosts[0].replace(/(^\s*hostname *)([a-zA-Z0-9_\-\#]+)/ig, "$2");
				}
				
				item.userList = new ArrayCollection(content.match(/^\s*username.+/igm));
				_targetFileList[index] = item;
				_targetFileList.refresh();
				_readCount
				
				_fileStream = new FileStream();
				_fileStream.addEventListener(Event.COMPLETE, onComplete);
				_fileStream.addEventListener(ProgressEvent.PROGRESS, onProcess);
				_fileStream.addEventListener(IOErrorEvent.IO_ERROR, onError);
				_fileStream.openAsync(item.file, FileMode.READ);
			}else{
				trace("Not found logs");
			}
		}
		
		[Bindable]
		public function get isRunnig():Boolean
		{
			return _isRunnig;
		}
		
		public function set isRunnig(value:Boolean):void
		{
			_isRunnig = value;
		}
		
		[Bindable]
		public function get readCount():uint
		{
			return _readCount;
		}
		
		public function set readCount(value:uint):void
		{
			var e:Event = new Event(FileListEvent.DIRECTORY_LISTING);
			dispatchEvent(e);
			_readCount = value;
		}
		
		[Bindable]
		public function get fileList():ArrayCollection
		{
			return _targetFileList;
		}
		
		public function set fileList(value:ArrayCollection):void
		{
			_targetFileList = value;
		}
		
		public function selectHostListFile(defaultPath:String = null):void
		{
			_file = new File();
			_file.addEventListener(Event.SELECT, onHostListSelect);
			_file.browse();
		}
		
		protected function onHostListSelect(event:Event):void
		{
			dispatchEvent(new FileReaderEvent(FileReaderEvent.HOSTLIST_SELECT, _file));
		}
	}
}