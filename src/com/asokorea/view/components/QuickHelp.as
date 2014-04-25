package com.asokorea.view.components
{
	import flash.events.MouseEvent;
	
	import mx.events.FlexMouseEvent;
	
	
	import spark.components.BorderContainer;
	import spark.components.Group;
	import spark.components.Label;
	import spark.components.PopUpAnchor;
	import spark.components.supportClasses.SkinnableComponent;
	
	public class QuickHelp extends SkinnableComponent
	{
		[SkinPart(required="true",type="spark.components.BorderContainer")]
		public var helpArea:BorderContainer;
		[SkinPart(required="true",type="spark.components.Group")]
		public var target:Group;
		[SkinPart(required="true",type="spark.components.PopUpAnchor")]
		public var popUp:PopUpAnchor;
		[SkinPart(required="true",type="spark.components.Label")]
		public var helpText:Label;
		[SkinPart(required="true",type="spark.components.Group")]
		public var close:Group;
		
		private var _text:String = "";
		
		public function QuickHelp()
		{
			super();
			this.mouseEnabled = true;
			this.setStyle("skinClass", Class(QuickHelpSkin));
		}
		
		override protected function partAdded(partName:String, instance:Object) : void{
			super.partAdded(partName, instance);
			
			if (instance==helpText){
				helpText.text = _text;
			}
			if (instance==target){
				target.buttonMode=true;
				target.mouseChildren=false;
				target.addEventListener(MouseEvent.CLICK, onShow);
			}
			if (instance==close){
				close.buttonMode=true;
				close.mouseChildren=false;
				close.addEventListener(MouseEvent.CLICK, onHide);
			}
		}
		
		private function onShow(event:MouseEvent):void{
			this.skin.currentState = "open";
		}
		private function onHide(event:MouseEvent):void{
			this.skin.currentState = "normal";
		}
		
		
		public function set text(t:String):void{
			_text = t;
			if (helpText) helpText.text = t;
		}
		public function get text():String{
			return _text;
		}
	}
}