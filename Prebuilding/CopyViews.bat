@echo off
REM Param1: source folder
REM Param2: destination folder
set sourceRoot=%~1
set destinationRoot=%~2

echo  "%sourceRoot%\Areas\Dedon\Views\*.cshtml" "%destinationRoot%\Areas\Dedon\Views" /f /i /y /s
xcopy "%sourceRoot%\Areas\Dedon\Views\*.cshtml" "%destinationRoot%\Areas\Dedon\Views" /f /i /y /s


