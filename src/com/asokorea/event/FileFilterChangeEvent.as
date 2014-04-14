package com.asokorea.event
{
	import com.asokorea.supportclass.IFilter;

	import flash.events.Event;
	import flash.net.FileFilter;

	public class FileFiterChangeEvent extends Event
	{
		public static const FILE_FILTER_CHANGE:String="fileFilterChange";

		[Bindable]
		public var filter:IFilter;

		public function FileFiterChangeEvent(type:String, fileFilter:FileFilter)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone():Event
		{
			return new FileFiterChangeEvent(this.type, true, false, this.filter);
		}
	}
}
