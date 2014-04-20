package com.asokorea.event
{
	import com.asokorea.model.vo.TaskVo;
	
	import flash.events.Event;
	
	public class TaskEvent extends Event
	{
		public static const ADD:String = "add";
		public static const OPEN:String = "open";
		public static const EDIT:String = "edit";
		public static const DELETE:String = "delete";
		public static const EXECUTE:String = "execute";
		
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

		public function get taskVo():TaskVo
		{
			return _task;
		}
	}
}