package com.asokorea.event
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class LoopEvent extends Event
	{
		public static const DO_LOOP:String = "doLoop";
		
		private var _currentItem:* = null;
		private var _currentPosition:int = -1;
		private var _lastPosition:int = -1;
		private var _list:ArrayCollection = null;
		
		public function LoopEvent(type:String, list:ArrayCollection, currentPosition:int = 0)
		{
			super(type, true, true);
			_list = list;
			_currentPosition = currentPosition;
			
			if(list)
			{
				_lastPosition = list.length - 1;
				_currentItem = (_currentPosition <= _lastPosition) ? list.getItemAt(_currentPosition) : null;
			}				
		}
		
		override public function clone():Event
		{
			return new LoopEvent(type, _list, _currentPosition);
		}

		public function get currentItem():*
		{
			return _currentItem;
		}

		public function get currentPosition():int
		{
			return _currentPosition;
		}

		public function get lastPosition():int
		{
			return _lastPosition;
		}

		public function get list():ArrayCollection
		{
			return _list;
		}

	}
}
