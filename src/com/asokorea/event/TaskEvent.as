package com.asokorea.event
{
	import flash.events.Event;
	
	public class TaskEvent extends Event
	{
		static public const ADD:String = "add";
		
		private var _taskName:String;
		
		public function TaskEvent(type:String, taskName:String = null)
		{
			super(type, true, true);
			_taskName = taskName;			
		}
		
		override public function clone():Event
		{
			return new TaskEvent(type, taskName);
		}

		public function get taskName():String
		{
			return _taskName;
		}
	}
}