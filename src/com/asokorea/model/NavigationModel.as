package com.asokorea.model
{
	import com.asokorea.model.enum.MainCurrentState;
	

	public class NavigationModel
	{
		/**
		 * Application path using by views to set its current view states 
		 * An current application path is defined by constants located below
		 * 
		 */		
		[Bindable]
		public var path:String = PATH_LOGGED_OUT;
		
		[Bindable]
		public var MAIN_CURRENT_SATAE:String = MainCurrentState.FIRST;

		public static const MAIN_FIRST:String = "FIRST";
		public static const MAIN_OPEN:String = "OPEN";
		public static const MAIN_SELECTED:String = "SELECTED";
		
		public static const PATH_LOGGED_OUT:String 			= "loggedOut";
		public static const PATH_LOGGED_IN:String 			= "loggedIn";
		
		public static const PATH_EMPLOYEE_LIST:String 		= PATH_LOGGED_IN + "/employeeList";
		public static const PATH_EMPLOYEE_DETAIL:String 	= PATH_LOGGED_IN + "/employeeDetail";	
		
	}
}