package com.asokorea.supportclass
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	
	public class NativeUpdater
	{
		protected static const UPDATE_DESCRIPTOR_URL:String = "https://bitbucket.org/yesican/nolsia/downloads/update.xml";
		protected var updateFile:File;
		protected var fileStream:FileStream;
		
		[Bindable]
		public var urlStream:URLStream;
		[Bindable]
		public var updateVersion:String;
		[Bindable]
		public var currentVersion:String;
		[Bindable]
		public var updateUrl:String;
		[Bindable]
		public var hasUpdate:Boolean;

		public function init():void
		{
			var updateDescLoader:URLLoader = new URLLoader;
			updateDescLoader.addEventListener(Event.COMPLETE, updateDescLoader_completeHandler);
			updateDescLoader.addEventListener(IOErrorEvent.IO_ERROR, updateDescLoader_ioErrorHandler);
			updateDescLoader.load(new URLRequest(UPDATE_DESCRIPTOR_URL));
		}
		
		protected function updateDescLoader_completeHandler(event:Event):void
		{
			try
			{
				var loader:URLLoader = URLLoader(event.currentTarget);
				closeUpdateDescLoader(loader);
				
				var updateDescriptor:XML = XML(loader.data);
				var udns:Namespace = updateDescriptor.namespace();
				var applicationDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
				var adns:Namespace = applicationDescriptor.namespace();
				
				updateVersion = updateDescriptor.udns::versionNumber.toString();
				currentVersion = applicationDescriptor.adns::versionNumber.toString();
				
				if (currentVersion != updateVersion)
				{
					updateUrl = updateDescriptor.udns::url.toString();
					hasUpdate = true;
				} else {
					hasUpdate = false;
				}				
			} 
			catch(error:Error) 
			{
				trace(error.message);
			}
		}
		
		protected function updateDescLoader_ioErrorHandler(event:IOErrorEvent):void
		{
			closeUpdateDescLoader(URLLoader(event.currentTarget));
			Alert.show("ERROR loading update descriptor:", event.text);
		}
		
		protected function closeUpdateDescLoader(loader:URLLoader):void
		{
			loader.removeEventListener(Event.COMPLETE, updateDescLoader_completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, updateDescLoader_ioErrorHandler);
			loader.close();
		}
		
		public function downloadUpdate():void
		{
			if(updateUrl)
			{
				var fileName:String = updateUrl.substr(updateUrl.lastIndexOf("/") + 1);

				updateFile = File.createTempDirectory().resolvePath(fileName);
				urlStream = new URLStream();
				urlStream.addEventListener(Event.OPEN, urlStream_openHandler);
				urlStream.addEventListener(ProgressEvent.PROGRESS, urlStream_progressHandler);
				urlStream.addEventListener(Event.COMPLETE, urlStream_completeHandler);
				urlStream.addEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);
				urlStream.load(new URLRequest(updateUrl));				
			}
		}
		
		protected function urlStream_openHandler(event:Event):void
		{
			fileStream = new FileStream;
			fileStream.open(updateFile, FileMode.WRITE);
		}
		
		protected function urlStream_progressHandler(event:ProgressEvent):void
		{
			var loadedBytes:ByteArray = new ByteArray;
			urlStream.readBytes(loadedBytes);
			fileStream.writeBytes(loadedBytes);
		}
		
		protected function urlStream_completeHandler(event:Event):void
		{
			closeStreams();
			installUpdate();
		}
		
		protected function installUpdate():void
		{
			try
			{
				var info:NativeProcessStartupInfo = new NativeProcessStartupInfo;
				info.executable = updateFile;
				
				var process:NativeProcess = new NativeProcess;
				process.start(info);
				
				NativeApplication.nativeApplication.exit();				
			} 
			catch(error:Error) 
			{
				trace(error.message);
			}
		}
		
		protected function urlStream_ioErrorHandler(event:IOErrorEvent):void
		{
			closeStreams();
			Alert.show("ERROR downloading update:", event.text);
		}
		
		protected function closeStreams():void
		{
			urlStream.removeEventListener(Event.OPEN, urlStream_openHandler);
			urlStream.removeEventListener(ProgressEvent.PROGRESS, urlStream_progressHandler);
			urlStream.removeEventListener(Event.COMPLETE, urlStream_completeHandler);
			urlStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);
			urlStream.close();
			
			if (fileStream)
				fileStream.close();
		}
		
		public function abort():void
		{
			if(urlStream)
			{
				closeStreams();
			}
			
			if(fileStream)
			{
				fileStream.close();
			}
			
			urlStream = null;
			fileStream = null;
		}
	}
}