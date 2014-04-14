package com.asokorea.controller
{
	import flash.events.IEventDispatcher;

	import org.swizframework.events.ChainEvent;
	import org.swizframework.utils.async.AsynchronousIOOperation;
	import org.swizframework.utils.chain.ChainType;
	import org.swizframework.utils.chain.CommandChain;

	public class HostLoopController
	{
		[Dispatcher]
		public var dispatcher:IEventDispatcher;

		public var commandChan:AsynchronousIOOperation

		[PostConstruct]
		public function init():void
		{
//			// Initializing sequential CommandChain, that will stop on errors
			var commandChain:CommandChain=new CommandChain(ChainType.PARALLEL, true);

//			// Registering event listener when chain execution is complete
			commandChain.addEventListener(ChainEvent.CHAIN_COMPLETE, commandChainComplete);
//			// Registering event listener in case chain execution fails
			commandChain.addEventListener(ChainEvent.CHAIN_FAIL, commandChainFail);
//			
//			// Adding async chain step that invokes remote AMF service
//			commandChain.addStep(
//				new AsyncCommandChainStep(
//					
//					remoteServiceDelegate.ping,
//					["ping param value"],
//					pingResultHandler,
//					pingFaultHandler));
//			// Adding function step that calls local function
//			commandChain.addStep(new FunctionChainStep(this.localFunction));
//			
//			// Initializing parallel event chain that will be nested in command chain
//			var eventChain:EventChain = new EventChain(dispatcher, ChainType.PARALLEL, true);
//			// Registering event listener when event chain execution is complete
//			eventChain.addEventListener(ChainEvent.CHAIN_COMPLETE, eventChainComplete);
//			// Registering event listener in case chain execution fails
//			eventChain.addEventListener(ChainEvent.CHAIN_FAIL, eventChainFail);
//			
//			// Adding event chain step that will dispatch INIT_PERSISTENCE event,
//			// this event is mediated in PersistenceController
//			eventChain.addEvent(new EventChainStep("INIT_PERSISTENCE"));
//			// Adding event chain step that will dispatch INIT_SOMETHING_ELSE event,
//			// this event is NOT mediated anywhere, this just for example and better understanding
//			// eventChain.addEvent(new EventChainStep("INIT_SOMETHING_ELSE"));
//			
//			// Nesting event chain in parent command chain
//			commandChain.addStep(eventChain);
//			// Starting whole command chain
//			commandChain.start();
		}




//		private function localFunction():void
//		{
//			trace("Running localFunction");
//		}
//		
//		public function pingResultHandler(event:ResultEvent):void
//		{
//			trace("Received result from remote ping call:", event.result);
//		}
//		
//		public function pingFaultHandler(event:FaultEvent):void
//		{
//			trace(event.fault.faultDetail);
//		}
//		
		private function commandChainComplete(event:ChainEvent):void
		{
			trace("CommandChain complete");
		}

		private function eventChainComplete(event:ChainEvent):void
		{
			trace("EventChain complete");
		}

		private function commandChainFail(event:ChainEvent):void
		{
			trace("CommandChain failed");
		}
//		
//		private function eventChainFail(event:ChainEvent):void
//		{
//			trace("EventChain failed");
//		}
	}
}
