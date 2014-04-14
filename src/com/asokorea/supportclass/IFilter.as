package com.asokorea.supportclass
{
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import mx.collections.ArrayCollection;

	public interface IFilter
	{
		function filtering(source:Vector.<File>, fileFilter:FileFilter = null):ArrayCollection;
	}
}