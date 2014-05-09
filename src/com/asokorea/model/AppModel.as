package com.asokorea.model
{
	import com.asokorea.model.vo.HostVo;
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	import com.asokorea.supportclass.NativeUpdater;
	import com.asokorea.util.ExcelUtil;
	import com.asokorea.util.MultiSSH;
	
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	import org.swizframework.storage.SharedObjectBean;

	[Bindable]
	public class AppModel
	{
		public var appName:String;

		public var appVersionLabel:String;

		public var selectedHostListFile:File;

		public var hostFileTypeFilter:Array=[new FileFilter("All File", "*.*"), new FileFilter("Excel File (*.xls;*.xlsx)", "*.xls;*.xlsx"), new FileFilter("Text File (*.txt;*.xml;*.json,*.csv)", "*.txt;*.xml;*.json,*.csv")];

		public var fileFilters:Array=[new FileFilter("All File", "*.*"), new FileFilter("Log File (*.txt;*.log)", "*.txt;*.log")];

		public var settingsVo:SettingsVo;

		public var selectedTaskVo:TaskVo;
		
		public var hasHostList:Boolean;
		
		public var message:String;
		
		public var standardOutput:String;
		
		public var standardError:String;
		
		public var updater:NativeUpdater;
		
		public var hostCount:int = 0;

		public var successHostCount:int = 0;

		public var failHostCount:int = 0;

		public var ipHostCount:int = 0;
		
		public var excelUtil:ExcelUtil;
		
		public var multiSSH:MultiSSH;
		
		public var standardUserList:ArrayCollection;

		public var standardUserMap:Dictionary;

		public var standardUserCount:int = 0;
		
		public var totalUsersCount:int = 0;
		
		public var userTypeList:ArrayCollection;
	}
}
