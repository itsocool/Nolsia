package com.asokorea.event
{
	import com.asokorea.model.vo.TaskVo;
	
	import flash.events.Event;
	
	public class TaskEvent extends Event
	{
		static public const ADD:String = "add";
		static public const OPEN:String = "open";
		static public const EDIT:String = "edit";
		static public const DELETE:String = "DELETE";
		
		private var _task:TaskVo;
		
		public function TaskEvent(type:String, task:TaskVo = null)
		{
			super(type, true, true);
			_task = task;			
		}
		
		override public function clone():Event
		{
			return new TaskEvent(type, _task);
		}

		public function get task():TaskVo
		{
			return _task;
		}
	}
}