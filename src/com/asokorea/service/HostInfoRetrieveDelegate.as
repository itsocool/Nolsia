package com.asokorea.service
{
	import mx.rpc.AsyncToken;
	import mx.rpc.remoting.RemoteObject;

	public class HostInfoRetrieveDelegate
	{
		[Inject]
		public var remoteObject:RemoteObject;

		public function ping(param:String):AsyncToken
		{
			return remoteObject.ping(param);
		}
	}
}


