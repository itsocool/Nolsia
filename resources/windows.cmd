@echo off
@set currdir=%~dp0
@cd /d "%currdir%"
@java -version >NUL 2>&1
if %ERRORLEVEL% == 0 goto FOUND
 	echo [ERROR:SYSTEM] Not found java >&2
goto END

:FOUND

	if not exist C:\Windows\System32\msvcp100.dll (
	    copy /y .\bin\msvcp100.dll C:\Windows\System32\msvcp100.dll
	)
	
	if not exist C:\Windows\System32\msvcr100.dll (
	    copy /y .\bin\msvcr100.dll C:\Windows\System32\msvcr100.dll
	)

	if %1 == excel goto EXCEL
	if %1 == ssh goto SSH
	if %1 == explorer goto EXPLORER
	if %1 == open goto OPEN

:EXCEL
	@set tmp=%~2
	@set src=%tmp:[_]= %
	.\bin\jre7\bin\java -jar .\bin\Excel2Xml.jar "%src%"
	goto END
	
:SSH
	@chcp 65001 > null
	@set tmp=%~2
	@set src=%tmp:[_]= %
	@set taskname=%3
	
	.\bin\jre7\bin\java -jar .\bin\MultiSSH.jar "%src%" %taskname%
	goto END	
	
:END
