@echo off
rem StrictDocStarter - try-json-query-ja.bat
rem
rem A guided trial of the JSON query workflow taught in chapter 4 of
rem samples\md-basic-ja\00-guide.md (and 00-guide.sdoc): export the whole
rem project to JSON, then pull answers out of it with jq. Each step prints an
rem explanation, waits for Enter, and runs the command it just described.
rem Type q at any prompt to stop.
rem
rem Drop a project folder on this file to use it. With no folder, the bundled
rem samples\md-basic-ja is used, so the output matches the guide exactly.
rem JSON is written to exported-json\ next to this file (git-ignored).
rem
rem WHY THE EXPLANATIONS LIVE IN SEPARATE .txt FILES
rem
rem The audience reads Japanese, but the Japanese cannot be written here.
rem cmd.exe parses a batch file's bytes using the OEM code page no matter what,
rem and "chcp 65001" only changes how output is drawn, not how the file is
rem parsed. A UTF-8 batch file therefore has its Japanese lines split mid
rem sentence, and the tail runs as a command:
rem
rem     'to nazorimasu.' is not recognized as an internal or external command
rem
rem Measured on Windows 11 / cmd.exe: some lines survive and some do not,
rem depending on where the byte boundaries fall, which is worse than failing
rem outright. So every Japanese line lives in jq-samples\lesson-ja\*.txt and is
rem printed with "type", which copies bytes through without parsing them. That
rem keeps this file pure ASCII (NFR-010 / ADR-008) with no exemption needed.
rem
rem Output language: English ASCII only, like every other .bat here.

rem WHY THIS ONE DOES NOT CALL _lib\elevate.bat (FR-806)
rem
rem Every other entry .bat here calls it. This one has no use for any of its
rem three jobs, and calling it would print two lines of unrelated PowerShell
rem chatter ("Stripping Mark-of-the-Web under ...") at the top of a tutorial.
rem
rem   UAC elevation - nothing is installed or written outside this folder.
rem   MOTW strip    - that unblocks .ps1 files so PowerShell will load them.
rem                   This script runs no PowerShell at all: only strictdoc,
rem                   jq and built-in commands.
rem   CWD normalize - every path below is built from %~dp0, so the current
rem                   directory is never consulted.

setlocal EnableExtensions

rem UTF-8 for OUTPUT: the .txt and .jq files below are UTF-8, and "type" copies
rem their bytes straight to the console. Also makes --arg carry Japanese safely
rem (step 5 shows what happens without it).
rem
rem KNOWN LIMIT: after this line, "set /p" no longer reads REDIRECTED standard
rem input -- measured, the variable comes back empty. Type at the prompts; do
rem not drive this script by piping a file into it. Reading from the console is
rem a different path and is unaffected.
chcp 65001 >nul

set "ROOT=%~dp0"
set "OUTDIR=%ROOT%exported-json"
set "JQDIR=%ROOT%jq-samples"
set "LESSON=%JQDIR%\lesson-ja"
set "JSON=%OUTDIR%\json\index.json"
set "BAR============================================================"

rem ---- which project? a dropped folder wins; a dropped file uses its parent --
if "%~1"=="" (
    set "PROJECT=%ROOT%samples\md-basic-ja"
) else if exist "%~1\" (
    set "PROJECT=%~f1"
) else (
    set "PROJECT=%~dp1"
)

rem ---- both tools must be on PATH (setup-strictdoc.bat installs them) --------
where strictdoc >nul 2>&1
if errorlevel 1 (
    echo [ERROR] strictdoc not found on PATH. Run setup-strictdoc.bat first.
    goto :fail
)
where jq >nul 2>&1
if errorlevel 1 (
    echo [ERROR] jq not found on PATH. Run setup-strictdoc.bat first.
    goto :fail
)

cls
echo %BAR%
echo  JSON query trial
echo %BAR%
echo.
type "%LESSON%\00-intro.txt"
echo.
echo  Project : %PROJECT%
echo  JSON    : %OUTDIR%
echo  Queries : %JQDIR%
echo.

rem ===========================================================================
echo %BAR%
echo  Step 1 / 7   Export the whole project to JSON
echo %BAR%
echo.
type "%LESSON%\01-export.txt"
echo.
echo  Command:
echo    strictdoc export "%PROJECT%" --formats=json --output-dir "%OUTDIR%"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
strictdoc export "%PROJECT%" --formats=json --output-dir "%OUTDIR%"
if not exist "%JSON%" (
    echo.
    echo [ERROR] %JSON% was not produced. Read the output above.
    goto :fail
)
echo.
echo  Done: %JSON%
echo.

rem ===========================================================================
echo %BAR%
echo  Step 2 / 7   A query in a .jq file, written in English
echo %BAR%
echo.
type "%LESSON%\02-jq-file-en.txt"
echo.
echo  ---- jq-samples\01-open-findings-en.jq ----
type "%JQDIR%\01-open-findings-en.jq"
echo  ------------------------------------------
echo.
echo  Command:
echo    jq -r -f "%JQDIR%\01-open-findings-en.jq" "%JSON%"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
jq -r -f "%JQDIR%\01-open-findings-en.jq" "%JSON%"
echo.

rem ===========================================================================
echo %BAR%
echo  Step 3 / 7   The same query written inline, in English
echo %BAR%
echo.
type "%LESSON%\03-inline-en.txt"
echo.
rem No carets before the pipes: inside the double quotes of an echo, "^" is not
rem an escape and would be printed literally, which is what a reader would then
rem copy and fail with.
echo  Command:
echo    jq -r ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"FINDING\") | .UID + \"  \" + .TITLE" "%JSON%"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
jq -r ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"FINDING\") | .UID + \"  \" + .TITLE" "%JSON%"
echo.

rem ===========================================================================
echo %BAR%
echo  Step 4 / 7   A query in a .jq file, written in Japanese
echo %BAR%
echo.
type "%LESSON%\04-jq-file-ja.txt"
echo.
echo  ---- jq-samples\02-keyword-ja.jq ----
type "%JQDIR%\02-keyword-ja.jq"
echo  ------------------------------------
echo.
echo  Command:
echo    jq -r -f "%JQDIR%\02-keyword-ja.jq" "%JSON%"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
jq -r -f "%JQDIR%\02-keyword-ja.jq" "%JSON%"
echo.

rem ===========================================================================
echo %BAR%
echo  Step 5 / 7   The same word passed on the command line instead
echo %BAR%
echo.
type "%LESSON%\05-arg-ja.txt"
echo.
rem The keyword is read from a file rather than typed here, because this file
rem must stay ASCII. On the command line it is an ordinary argument either way,
rem which is exactly the case being demonstrated.
set "KW="
set /p "KW="<"%LESSON%\keyword.txt"
echo  Keyword read from jq-samples\lesson-ja\keyword.txt: %KW%
echo.
echo  Command:
echo    jq -r --arg kw %KW% "(the same filter as step 4, with contains($kw))" "%JSON%"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
jq -r --arg kw "%KW%" ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"REQUIREMENT\") | select(((.TITLE // \"\") + (.STATEMENT // \"\")) | contains($kw)) | .UID + \"  \" + .TITLE" "%JSON%"
echo.

rem ===========================================================================
echo %BAR%
echo  Step 6 / 7   Take the answer as JSON instead of text
echo %BAR%
echo.
type "%LESSON%\06-json-out.txt"
echo.
echo  ---- jq-samples\03-findings-json.jq ----
type "%JQDIR%\03-findings-json.jq"
echo  ---------------------------------------
echo.
echo  Command (note: no -r):
echo    jq -f "%JQDIR%\03-findings-json.jq" "%JSON%"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
jq -f "%JQDIR%\03-findings-json.jq" "%JSON%"
echo.

rem ===========================================================================
echo %BAR%
echo  Step 7 / 7   Fix the Japanese inside the JSON file itself
echo %BAR%
echo.
type "%LESSON%\07-readable.txt"
echo.
echo  Command:
echo    jq . "%JSON%" ^> "%OUTDIR%\readable.json"
echo    jq -c . "%JSON%" ^> "%OUTDIR%\min.json"
echo.
call :ask
if errorlevel 1 goto :quit
echo.
jq . "%JSON%" > "%OUTDIR%\readable.json"
jq -c . "%JSON%" > "%OUTDIR%\min.json"
echo  Sizes:
for %%F in ("%JSON%" "%OUTDIR%\readable.json" "%OUTDIR%\min.json") do @echo    %%~nxF  %%~zF bytes
echo.

rem ===========================================================================
echo %BAR%
echo  Finished
echo %BAR%
echo.
type "%LESSON%\99-end.txt"
echo.
echo  Everything landed in %OUTDIR% (git-ignored).
echo.
goto :end

rem ---------------------------------------------------------------------------
:ask
set "ANS="
set /p "ANS=  [Enter] run   /   q [Enter] quit : "
if /i "%ANS%"=="q" exit /b 1
exit /b 0

:quit
echo.
echo  Stopped. What ran so far is in %OUTDIR%.
goto :end

:fail
echo.
pause
endlocal & exit /b 1

:end
echo.
pause
endlocal & exit /b 0
