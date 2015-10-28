@echo off
REM Param1: source folder
REM Param2: destination folder
set sourceRoot=%~1
set destinationRoot=%~2

if "%sourceRoot%" == "" (goto errorSource)
if "%destinationRoot%" == "" (goto errorDestination)

echo # # CLEANING destination folder %destinationRoot%\ 
RD /S /Q "%destinationRoot%\"

echo # # COPY Files from %sourceRoot%\ folders to %destinationRoot%\ folders
xcopy "%sourceRoot%\css\*.css" "%destinationRoot%\css\" /f /i /y /s
xcopy "%sourceRoot%\fonts\*.*" "%destinationRoot%\fonts\" /f /i /y /s
xcopy "%sourceRoot%\img\*.png" "%destinationRoot%\img\" /f /i /y /s
xcopy "%sourceRoot%\img\*.ico" "%destinationRoot%\img\" /f /i /y /s
xcopy "%sourceRoot%\img\*.gif" "%destinationRoot%\img\" /f /i /y /s
xcopy "%sourceRoot%\img\*.jpg" "%destinationRoot%\img\" /f /i /y /s
xcopy "%sourceRoot%\ts\*.js" "%destinationRoot%\js\" /f /i /y /s
xcopy "%sourceRoot%\js\*.js" "%destinationRoot%\js\" /f /i /y /s
goto eof

:errorSource
echo # # ERROR Source path missing.
goto eof

:errorDestination
echo # # ERROR Destination path missing.
goto eof

:eof