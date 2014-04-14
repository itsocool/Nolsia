package com.asokorea.supportclass
{
	import flash.filesystem.File;
	import flash.net.FileFilter;

	import mx.collections.ArrayCollection;

	public class DefaultFilter implements IFilter
	{
		public function filtering(source:Vector.<File>, fileFilter:FileFilter=null):ArrayCollection
		{
			var result:ArrayCollection=new ArrayCollection();
			var index:uint=0;

			for each (var file:File in source)
			{
				result.addItem(new FileItemVO(index++, file));
			}

			return result;
		}
	}
}
