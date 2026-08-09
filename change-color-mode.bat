@echo off
rem StrictDocStarter - colour mode switcher.
rem Writes "color_mode" (auto / light / dark) into server.config.json. The next
rem time you open a project with launch-strictdoc.bat, that project picks up the
rem new mode. Nothing is applied to servers that are already running.
rem
rem Admin not required. Common elevation / MOTW / CWD handled by
rem _lib\elevate.bat (FR-806).

setlocal EnableExtensions

call "%~dp0_lib\elevate.bat" no_admin "%~f0" "%*"
if "%ERRORLEVEL%"=="99" exit /b 0
if errorlevel 1 exit /b %ERRORLEVEL%

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0change-color-mode.ps1"
set "PS_EXIT=%ERRORLEVEL%"

echo.
echo ============================================================
echo change-color-mode finished. Exit code: %PS_EXIT%
echo ============================================================
pause

endlocal & exit /b %PS_EXIT%
