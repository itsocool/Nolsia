package com.asokorea.supportclass
{
	import org.osflash.thunderbolt.Logger;

	public class LOG
	{
		private static var logger:Logger;
		
		public static function log(level:String, msg:String = "", logObjects:Array = null):void
		{
			Logger.log(level, msg, logObjects);
		}
		
		public static function error(msg:String = null, ...parameters):void
		{
			Logger.error(msg, parameters);
		}
		
		public static function worn(msg:String = null, ...parameters):void
		{
			Logger.warn(msg, parameters);
		}
		
		public static function info(msg:String = null, ...parameters):void
		{
			Logger.info(msg, parameters);
		}
		
		public static function debug(msg:String = null, ...parameters):void
		{
			Logger.debug(msg, parameters);
		}
	}
}