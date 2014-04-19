@echo off
@set currdir=%~dp0
@cd /d "%currdir%"
@java -version >NUL 2>&1
if %ERRORLEVEL% == 0 goto FOUND
 	echo [Not found java] >&2
goto END

:FOUND
	@set task=%1

	.\bin\jre7\bin\java -Xms16m -Xmx1024m -jar .\bin\MultiSSH.jar %task%

	if not %ERRORLEVEL% == 0 echo [ERROR] >&2
goto end
	
:END