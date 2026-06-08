@echo off
rem launch-strictdoc - StrictDoc launcher (v1.2, option C: pure launcher, no menu).
rem Drag a folder or file onto this .bat to serve it (a file uses its parent folder),
rem or double-click to be prompted. Opens the StrictDoc server in its own window + browser.
rem Admin not required. Common MOTW / CWD handled by _lib\elevate.bat (FR-806).
rem Spec: docs/serve-spec.md (FR-1101 / FR-1121 / FR-1150 series). ASCII only (NFR-005 / ADR-008).

setlocal EnableExtensions

call "%~dp0_lib\elevate.bat" no_admin "%~f0" "%*"
if "%ERRORLEVEL%"=="99" exit /b 0
if errorlevel 1 exit /b %ERRORLEVEL%

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0launch-strictdoc.ps1" %*
set "PS_EXIT=%ERRORLEVEL%"

rem No trailing pause: on success this launcher window closes (the StrictDoc server runs
rem in its own window). On a startup error the .ps1 pauses itself before exiting (FR-1157c).
endlocal & exit /b %PS_EXIT%
