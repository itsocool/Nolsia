@echo off
@set currdir=%~dp0
@cd /d "%currdir%"
@java -version >NUL 2>&1
if %ERRORLEVEL% == 0 goto FOUND
 	echo [Not found java] >&2
goto END

:FOUND
	@set tmp=%1
	@set src=%tmp:[_]= %
	@set str1=%*
	@set str2=%str1:-f=%
	@set str3=%str1:-exe=%
	@set opt=


if not "%str1%" == "%str2%" set opt=-f

if "%str1%"=="%str3%" (
	goto JAR
) else (
	goto EXE
)

:JAR
	.\jre7\bin\java -Xms16m -Xmx1024m -jar Excel2Xml.jar "%src%" %opt%
	goto END

:EXE
	Excel2Xml.exe "%src%" %opt%
	goto END

:END
