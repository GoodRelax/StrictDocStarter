@echo off
rem open-strictdoc-launcher - start StrictDoc's own desktop launcher.
rem
rem This is NOT launch-strictdoc.bat. The difference is worth knowing before you
rem pick one:
rem
rem   launch-strictdoc.bat        this project's launcher. Drag a folder onto it.
rem                               One window per document, so several documents
rem                               can be open side by side. Checks the encoding
rem                               and line endings of your sources first.
rem
rem   open-strictdoc-launcher.bat StrictDoc's own launcher, added in 0.22.0 and
rem                               still marked experimental. A Tk window: you pick
rem                               one workspace, and it serves one at a time. It
rem                               also exports, edits the project config, repairs
rem                               UIDs and runs git pull / commit / push.
rem
rem It takes no folder argument, so dropping one on this file does nothing.
rem
rem Admin not required. Common MOTW / CWD handled by _lib\elevate.bat (FR-806).
rem Output language: English ASCII only (NFR-010 / ADR-008).

setlocal EnableExtensions

call "%~dp0_lib\elevate.bat" no_admin "%~f0" "%*"
if "%ERRORLEVEL%"=="99" exit /b 0
if errorlevel 1 exit /b %ERRORLEVEL%

if not "%~1"=="" (
    echo [INFO]  StrictDoc's own launcher takes no folder argument, so what you
    echo         dropped is ignored. Choose the folder inside the window instead.
    echo         To open a folder by dropping it - and to open more than one at
    echo         a time - use launch-strictdoc.bat.
    echo.
)

where strictdoc >nul 2>&1
if errorlevel 1 (
    echo [ERROR] strictdoc is not on PATH.
    echo         Run setup-strictdoc.bat first, then open a new console window.
    echo.
    pause
    endlocal & exit /b 1
)

rem The launcher subcommand registers itself only when tkinter can be imported,
rem so ask strictdoc what it has rather than guessing.
strictdoc --help 2>nul | findstr /C:"launcher" >nul
if errorlevel 1 (
    echo [ERROR] This strictdoc has no "launcher" command. Two things cause that:
    echo           - strictdoc older than 0.22.0, which is where it was added
    echo           - a Python built without tkinter, which the launcher needs
    echo         Check your version with:  strictdoc version
    echo         launch-strictdoc.bat works either way.
    echo.
    pause
    endlocal & exit /b 1
)

echo [INFO]  Starting StrictDoc's own launcher. It is marked experimental.
echo         Choose a folder in the window that opens.
echo         This console window closes when you close that window.
echo.

strictdoc launcher
set "SD_EXIT=%ERRORLEVEL%"

if not "%SD_EXIT%"=="0" (
    echo.
    echo [ERROR] The launcher exited with code %SD_EXIT%.
    pause
)

endlocal & exit /b %SD_EXIT%
