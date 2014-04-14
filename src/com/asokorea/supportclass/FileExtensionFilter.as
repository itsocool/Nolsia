package com.asokorea.supportclass
{
	import flash.filesystem.File;
	import flash.net.FileFilter;

	import mx.collections.ArrayCollection;

	public class FileExtensionFilter implements IFilter
	{
		private var _fileFilter:FileFilter;

		public function FileExtensionFilter(fileFilter:FileFilter)
		{
			_fileFilter=fileFilter;
		}

		public function filtering(source:Vector.<File>, fileFilter:FileFilter=null):ArrayCollection
		{
			var result:ArrayCollection=new ArrayCollection();

			if (fileFilter.extension != "*.*")
			{
				var exts:Array=fileFilter.extension.split(";").map(function(item:String, index:int, array:Array):String
				{
					return item.split(".")[1];
				});

				source.filter(function(file:File, index:int, array:Array):Boolean
				{
					return exts.some(function(ext:String, i:int, arr:Array):Boolean
					{
						return (ext == "*" || ext == file.extension)
					});
				});
			}

			for each (var file:File in source)
			{
				result.addItem(file);
			}

			return result;
		}
	}
}