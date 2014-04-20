@echo off
@set currdir=%~dp0
@cd /d "%currdir%"
@java -version >NUL 2>&1
if %ERRORLEVEL% == 0 goto FOUND
 	echo [Not found java] >&2
goto END

:FOUND
	@set host=%1
	@set user=%2
	@set pass=%3
	@set port=%4
	@set command=%5

	..\..\Nolsia\src\assets\bin\jre7\bin\java -Xms16m -Xmx1024m -jar MultiSSH.jar 

goto end
	
:END