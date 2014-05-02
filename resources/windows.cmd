@echo off
@set currdir=%~dp0
@cd /d "%currdir%"
@.\bin\jre7\bin\java -version >NUL 2>&1
if %ERRORLEVEL% == 0 goto FOUND
 	echo "[EXCEPTION] Not found java">&2
goto END

:FOUND

	if not exist C:\Windows\System32\msvcp100.dll (
	    copy /y .\bin\msvcp100.dll C:\Windows\System32\msvcp100.dll
	)
	
	if not exist C:\Windows\System32\msvcr100.dll (
	    copy /y .\bin\msvcr100.dll C:\Windows\System32\msvcr100.dll
	)

	if %1 == import goto IMPORT
	if %1 == ssh goto SSH
	if %1 == shell goto SHELL
	if %1 == export goto EXPORT

:EXPORT
	@set tmp=%~2
	@set src=%tmp:[_]= %
	@set tmp2=%~3
	@set target=%tmp2:[_]= %
	.\bin\jre7\bin\java -jar .\bin\ExcelUtil.jar -export "%src%" "%target%"
	goto END

:IMPORT
	@set tmp=%~2
	@set src=%tmp:[_]= %
	.\bin\jre7\bin\java -jar .\bin\ExcelUtil.jar -import "%src%"
	goto END
	
:SSH
	REM @chcp 65001 > null
	@set tmp=%~2
	@set src=%tmp:[_]= %
	@set taskname=%3
	
	.\bin\jre7\bin\java -Xms32m -Xmx512m -jar .\bin\MultiSSH.jar "%src%" %taskname%
	goto END	

:SHELL
 	start bin\putty.exe -ssh %2	

	goto END
	

:END
