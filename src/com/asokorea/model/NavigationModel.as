package com.asokorea.model
{
	public class NavigationModel
	{
		public static const MAIN_FIRST:String = "FIRST";
		public static const MAIN_OPEN:String = "OPEN";
		public static const MAIN_PROCESS:String = "PROCESS";
		public static const MAIN_BUSY:String = "BUSY";
		public static const MAIN_UPDATE:String = "UPDATE";
		
		public static const TASK_EDIT:String = "EDIT";
		public static const TASK_ADD:String = "ADD";
		public static const TASK_COPY:String = "COPY";
		
		public static const PATH_LOGGED_OUT:String 			= "loggedOut";
		public static const PATH_LOGGED_IN:String 			= "loggedIn";
		
		public static const PATH_EMPLOYEE_LIST:String 		= PATH_LOGGED_IN + "/employeeList";
		public static const PATH_EMPLOYEE_DETAIL:String 	= PATH_LOGGED_IN + "/employeeDetail";	
		
		[Bindable]
		public var path:String = PATH_LOGGED_OUT;
		
		[Bindable]
		public var MAIN_CURRENT_SATAE:String = MAIN_FIRST;
	}
}