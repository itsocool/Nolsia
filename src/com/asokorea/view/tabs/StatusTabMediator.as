package org.drushpal.view.tabs
{
	import flash.events.MouseEvent;
	
	import mx.binding.utils.BindingUtils;
	
	import org.drushpal.service.DrushServiceEvent;
	import org.drushpal.service.DrushService;
	import org.drushpal.model.enum.DrushCommand;
	import org.robotlegs.mvcs.Mediator;
	
	import spark.components.ComboBox;
	
	public class StatusTabMediator extends Mediator
	{
		[Inject]public var statusTab:StatusTab;
		[Inject]public var drushService:DrushService;

		override public function onRegister():void{
			eventMap.mapListener(statusTab.btnClearCache,MouseEvent.CLICK,onClearCache);
			eventMap.mapListener(statusTab.btnCron,MouseEvent.CLICK,function(event:MouseEvent):void{ drushService.run(DrushCommand.CRON); });
			eventMap.mapListener(statusTab.btnRefresh,MouseEvent.CLICK,function(event:MouseEvent):void{ drushService.run(DrushCommand.REFRESH); });
						
			BindingUtils.bindProperty(statusTab,"statusCollection",drushService,"statusCollection");
		}
		private function onClearCache(event:MouseEvent):void{
			if(statusTab.cmbCache.selectedIndex == spark.components.ComboBox.CUSTOM_SELECTED_ITEM){
				drushService.run(DrushCommand.CLEAR_CACHE,[statusTab.cmbCache.selectedItem]);
			}else{
				drushService.run(DrushCommand.CLEAR_CACHE,[statusTab.cmbCache.selectedItem.cmd])
			}
		}
	}
}