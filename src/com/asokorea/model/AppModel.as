package com.asokorea.model
{
	import flash.filesystem.File;
	import flash.net.FileFilter;

	import mx.collections.ArrayCollection;

	import org.swizframework.storage.SharedObjectBean;

	public class AppModel
	{
		[Bindable]
		public var appName:String;

		[Bindable]
		public var appVersionLabel:String;

		[Bindable]
		public var hostFile:File;

		[Bindable]
		public var logDir:File;

		[Bindable]
		public var hostFileTypeFilter:Array=[new FileFilter("All File", "*.*"), new FileFilter("Excel File (*.xls;*.xlsx)", "*.xls;*.xlsx"), new FileFilter("Text File (*.txt;*.xml;*.json,*.csv)", "*.txt;*.xml;*.json,*.csv")];

		[Bindable]
		public var fileFilters:Array=[new FileFilter("All File", "*.*"), new FileFilter("Log File (*.txt;*.log)", "*.txt;*.log")];

		[Bindable]
		public var hostList:ArrayCollection;

		[Bindable]
		public var settings:ArrayCollection;

		[Bindable]
		public var lastTaskId:String;

	}
}
