package com.asokorea.presentation
{

	import com.asokorea.event.FileEventEX;
	import com.asokorea.event.FileReaderEvent;
	import com.asokorea.event.LoopEvent;
	import com.asokorea.model.AppModel;
	import com.asokorea.supportclass.FileExtensionFilter;
	import com.asokorea.supportclass.FileReader;
	import com.asokorea.supportclass.IFilter;
	import com.asokorea.util.Global;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import mx.collections.ArrayCollection;
	
	public class MainViewPresentationModel extends EventDispatcher
	{
		[Dispatcher]
		public var dispatcher:IEventDispatcher;

		[Bindable]
		[Inject]
		public var appModel:AppModel;

		[Bindable]
		[Inject]
		public var reader:FileReader;

		public function browseHostList():void
		{
			Global.log("host ");
			var e:FileEventEX = new FileEventEX(FileEventEX.HOSTLIST_FILE_BROWSE, appModel.hostFile);
			dispatcher.dispatchEvent(e);
		}
		
		public function selectLogDir():void
		{
			reader.selectLogDir();
		}

		public function readLog(filter:FileFilter):void
		{
			reader.readDirectory();
		}
		
		public function save(exportFormat:String):void
		{
			var file:File = new File(reader.selectedLogPath);
			dispatcher.dispatchEvent(new FileReaderEvent(FileReaderEvent.FILE_EXPORT, file));
		}
							 
		public function filterChange(fileFilter:FileFilter):void
		{
			var filter:IFilter = new FileExtensionFilter(fileFilter)
			reader.filtering(filter);
		}
		
		public function start(list:ArrayCollection):void
		{
			dispatcher.dispatchEvent(new LoopEvent(LoopEvent.DO_LOOP, list));
		}
		
//		protected function onPreinitialize(event:FlexEvent):void
//		{
//			var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
//			var ns:Namespace = appXml.namespace();
//			
//			appVersionLabel = appXml.ns::name.toString();
//			appVersionLabel += " " + appXml.ns::versionLabel[0].toString();
//			//				maximizeWindow(this.nativeWindow);
//		}			
//		
//		protected function init(event:FlexEvent):void
//		{
//			mySo = SharedObject.getLocal("Nolsia");
//			file = new File(mySo.data.defaultPath);
//			
//			if(!file.isDirectory)
//			{
//				file = File.applicationDirectory;
//			}
//			
//			reader = new FileReader(file);
//			//				reader.addEventListener(FileListEvent.DIRECTORY_LISTING, onListing);
//			//				reader.addEventListener(FileReaderEvent.READ_FILE_LIST, onRead);
//			reader.selectLogDir();
//			currentState = "OPEN";
//		}
//		


//		
//		protected function extFilterChange(event:IndexChangeEvent):void
//		{
//			if(logs && logs.length > 0)
//			{
//				filtering(logs, ddlExt.selectedItem["value"]);
//			}
//		}
//		
//		private function filtering(files:Array, filterExt:String):void
//		{
//			var col:ArrayCollection = new ArrayCollection();
//			var file:File;
//			var fileName:String;
//			var i:int = 0;
//			
//			for each (file in files) 
//			{
//				if(!file.isDirectory)
//				{
//					fileName = file.name;
//					if(filterExt == "*" || file.extension == filterExt)
//					{
//						col.addItem(new FileItemVO(i+1, files[i]));
//					}
//				}
//				i++;
//			}
//			
//			fileList = col;
//		}
//		
//		protected function readButtonClick(event:MouseEvent):void
//		{
//			//				var reader:FileReader = new FileReader(fileList, null);
//			reader.addEventListener("readCountChange", onChangeCount);
//			reader.start();
//		}
//		
//		private function getFileConten(item:FileItemVO):FileItemVO
//		{
//			var reader:FileStream = new FileStream();
//			var content:String = null;
//			var result:ArrayCollection = null;
//			var host:String = null;
//			
//			reader.open(item.file, FileMode.READ);
//			
//			content = reader.readUTFBytes(reader.bytesAvailable);
//			
//			var hosts:Array = content.match(/^\s*hostname *[a-zA-Z0-9_\-\#]+/igm);
//			
//			if(hosts is Array && hosts.length > 0)
//			{
//				item.host = hosts[0].replace(/(^\s*hostname *)([a-zA-Z0-9_\-\#]+)/ig, "$2");
//			}
//			item.userList = new ArrayCollection(content.match(/^\s*username.+/igm));
//			
//			reader.close();
//			reader = null;
//			content = null;
//			return item;
//		}
//		
//		public function maximizeWindow(nativeWin:NativeWindow):Boolean
//		{
//			if(nativeWin.displayState != NativeWindowDisplayState.MAXIMIZED)
//			{
//				var beforeState:String = nativeWin.displayState;
//				var afterState:String = NativeWindowDisplayState.MAXIMIZED;
//				var displayStateEvent:NativeWindowDisplayStateEvent = 
//					new NativeWindowDisplayStateEvent(NativeWindowDisplayStateEvent.DISPLAY_STATE_CHANGING,
//						true,true,beforeState,afterState);
//				nativeWin.dispatchEvent(displayStateEvent);
//				if(!displayStateEvent.isDefaultPrevented())
//				{
//					nativeWin.maximize();
//					return true;
//				} else {
//					return false;
//				}
//			}
//			return false;
//		}
//		
//		protected function button3_clickHandler(event:MouseEvent):void
//		{
//			var file:File = new File(tipPath.text);
//			file.addEventListener(Event.COMPLETE, onSelectSaveFile);
//			file.save("", "nolsia.html");
//		}
//		
//		protected function onSelectSaveFile(event:Event):void
//		{
//			var file:File = event.target as File;
//			var writer:FileStream = new FileStream();
//			writer.open(file, FileMode.APPEND);
//			writer.writeUTFBytes("<html>\n<head>\n<title>nolsia log file</title>\n</head>\n<body>\n");
//			writer.writeUTFBytes("\t<table border=1>\n\t<tr>\n");
//			writer.writeUTFBytes("\t\t<td>No</td>\n\t\t<td>Host Name</td>\n\t\t<td>user list</td>\n\t\t<td>user count</td>\n\t</tr>\n");
//			
//			var i:int = 0;
//			
//			for each (var item:FileItemVO in fileList) 
//			{
//				writer.writeUTFBytes("\t<tr>\n");
//				writer.writeUTFBytes("\t\t<td>");
//				writer.writeUTFBytes((i+1).toString());
//				writer.writeUTFBytes("</td>\n");
//				writer.writeUTFBytes("\t\t<td>");
//				writer.writeUTFBytes(StringUtil.trim(item.host));
//				writer.writeUTFBytes("</td>\n");
//				writer.writeUTFBytes("\t\t<td>");
//				writer.writeUTFBytes(item.userList.source.join("\n</br>"));
//				writer.writeUTFBytes("</td>\n");
//				writer.writeUTFBytes("\t\t<td>");
//				writer.writeUTFBytes(item.userList.length.toString());
//				writer.writeUTFBytes("</td>\n");
//				writer.writeUTFBytes("\t</tr>\n");
//				i++;
//			}
//			writer.writeUTFBytes("\t</table>\n");
//			
//			writer.writeUTFBytes("</body>\n</html>");
//			writer.close();
//		}
//		
//		[Bindable]
//		public function get readCount():int
//		{
//			return _readCount;
//		}
//		
//		public function set readCount(value:int):void
//		{
//			_readCount = value;
//		}
//		
//		protected function onChangeCount(event:Event):void
//		{
//			var reader:FileReader = event.target as FileReader;
//			lblReadCount.text = reader.readCount.toString();
//		}
//		
//		protected var _startupInfo:NativeProcessStartupInfo;
//		protected var process:NativeProcess;
//		protected var uuid:String;
//		
//		protected function button4_clickHandler(event:MouseEvent):void
//		{
//			process = new NativeProcess();
//			uuid = UIDUtil.createUID();
//			
//			var exeFile:File = File.applicationDirectory;
//			var args:Vector.<String> = Vector.<String>(['-v','-ssh','goldpick.co.kr','-T','-l','kth','-pw','g1493018']);
//			args = Vector.<String>(['-v','-ssh','goldpick.co.kr','-l','kth','-pw','g1493018']);
//			exeFile = exeFile.resolvePath("assets/bin/plink.exe");
//			_startupInfo = new NativeProcessStartupInfo();
//			_startupInfo.arguments = args;
//			_startupInfo.executable = exeFile;
//			
//			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onOutput);
//			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA,onProcessError);
//			process.addEventListener(NativeProcessExitEvent.EXIT,onExit);
//			process.start(_startupInfo);
//			txtErrot.text += "\n Start";
//		}
//		
//		public function onExit(e:NativeProcessExitEvent):void{
//			trace(e.exitCode); //TODO: alert something went wrong if there are exit codes
//			process.removeEventListener(NativeProcessExitEvent.EXIT,onExit);
//			process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA,onProcessError);
//			process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onOutput);
//			txtErrot.text += process.standardError.readMultiByte(process.standardError.bytesAvailable,"utf-8");
//			txtLog.text += process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,"utf-8");
//			txtErrot.text += "\nExit";
//		}
//		
//		public function onOutput(e:ProgressEvent):void{ 
//			var out:String = "";
//			if(process.running){				
//				out = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,"utf-8");
//				//					out = out.split("\r").join("\n");
//				txtLog.text+=out;
//				
//				txtErrot.text += process.standardError.readMultiByte(process.standardError.bytesAvailable,"utf-8")
//				txtErrot.text += "\nOutput";
//			}
//		}
//		
//		/**
//		 * Process error handling...
//		 * Sometimes stuff that's not an error comes through here... why? i'm not sure... but complete gets called eventually anyway.
//		 **/ 
//		public function onProcessError(e:ProgressEvent):void{
//			var out:String = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,"utf-8");
//			txtErrot.text += out;
//			txtErrot.text += "\nError";
//		}
//		
//		protected function button5_clickHandler(event:MouseEvent):void
//		{
//			process.standardInput.writeUTFBytes(tipCommand.text + "\r");
//		}







		//--------------------------------------------------------------------------
		//
		// view state
		//
		//--------------------------------------------------------------------------


		public static const CURRENT_STATE_CHANGED:String="currentStateChanged";

		private var _currentState:String;

		[Inject("navModel.MAIN_CURRENT_SATAE", bind="true")]
		[Bindable(event="currentStateChanged")]
		public function get currentState():String
		{
			return _currentState;
		}

		public function set currentState(value:String):void
		{
			if (_currentState != value)
			{
				_currentState=value;
				this.dispatchEvent(new Event(CURRENT_STATE_CHANGED));
			}
			trace(Global.classInfo);
		}

		//--------------------------------------------------------------------------
		//
		// public methods called by its view
		//
		//--------------------------------------------------------------------------

//		public function logout() : void 
//		{
//			dispatcher.dispatchEvent( new LoginEvent( LoginEvent.LOGOUT ) );
//		}
//		

	}
}