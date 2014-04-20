package com.asokorea.model
{
	import com.asokorea.model.vo.SettingsVo;
	import com.asokorea.model.vo.TaskVo;
	
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import mx.collections.ArrayCollection;
	
	import org.swizframework.storage.SharedObjectBean;

	[Bindable]
	public class AppModel
	{
		public var appName:String;

		public var appVersionLabel:String;

		public var hostFile:File;

		public var hostFileTypeFilter:Array=[new FileFilter("All File", "*.*"), new FileFilter("Excel File (*.xls;*.xlsx)", "*.xls;*.xlsx"), new FileFilter("Text File (*.txt;*.xml;*.json,*.csv)", "*.txt;*.xml;*.json,*.csv")];

		public var fileFilters:Array=[new FileFilter("All File", "*.*"), new FileFilter("Log File (*.txt;*.log)", "*.txt;*.log")];

		public var hostList:ArrayCollection;

		public var settingsVo:SettingsVo;

		public var lastTaskName:String;
		
		public var selectedTaskVo:TaskVo;
		
		public var hasHostList:Boolean;
		
		public var message:String;
		
		public var standardOutput:String;
		
		public var standardError:String;
	}
}
