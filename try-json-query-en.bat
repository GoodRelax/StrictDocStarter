@echo off
rem StrictDocStarter - try-json-query-en.bat
rem
rem A guided trial of the "Querying through JSON" chapter of
rem samples\md-basic-en\02-guide-for-human.md: export the whole project to
rem JSON, then pull answers out of it with jq. Each step prints an explanation,
rem waits for Enter, and runs the command it just showed. Type q at any prompt
rem to stop.
rem
rem Drop a project folder on this file to use it; with none, the bundled
rem samples\md-basic-en is used so the output matches the guide. JSON goes to
rem exported-json\ (git-ignored).
rem
rem This is the English twin of try-json-query-ja.bat. Three things here are
rem deliberate and easy to "fix" wrongly:
rem
rem 1. The lesson text lives in jq-samples\lesson-en\*.txt and is shown with
rem    "type", even though this file is ASCII and could carry English inline.
rem    Keeping the same shape as the Japanese trial means a change to one is
rem    obvious in the other. The Japanese one has no choice: cmd.exe parses a
rem    batch file's bytes with the OEM code page whatever chcp says, so UTF-8
rem    Japanese in a .bat gets split mid-sentence and the tail runs as a
rem    command.
rem 2. No _lib\elevate.bat call, unlike the other entry .bat files. Nothing is
rem    installed, no .ps1 is loaded (so there is no Mark-of-the-Web to strip),
rem    and "cd /d %~dp0" below covers the only part that mattered.
rem 3. After "chcp 65001", set /p stops reading REDIRECTED standard input. Type
rem    at the prompts; do not pipe a file into this script. A real console is
rem    unaffected.

setlocal EnableExtensions
chcp 65001 >nul

rem The dropped path must be resolved before the cd below; a dropped file uses
rem its parent folder.
set "PROJECT=%~dp0samples\md-basic-en"
if not "%~1"=="" if exist "%~1\" set "PROJECT=%~f1"
if not "%~1"=="" if not exist "%~1\" set "PROJECT=%~dp1"

rem Everything after this point uses short relative paths.
cd /d "%~dp0"

where strictdoc >nul 2>&1 || (echo [ERROR] strictdoc not on PATH. Run setup-strictdoc.bat first.& goto :fail)
where jq        >nul 2>&1 || (echo [ERROR] jq not on PATH. Run setup-strictdoc.bat first.& goto :fail)

cls
echo ============================================================
echo  JSON query trial
echo ============================================================
echo.
type "jq-samples\lesson-en\00-intro.txt"
echo.
rem The commands below are shown with relative paths, so say what they are
rem relative to -- otherwise they cannot be pasted into a shell that is
rem somewhere else.
echo  Project : %PROJECT%
echo  JSON    : exported-json\json\index.json
echo  Commands below run from: %CD%
echo.

rem ---------------------------------------------------------------------------
call :head 1 "Export the whole project to JSON" 01-export.txt
echo    strictdoc export "%PROJECT%" --formats=json --output-dir exported-json
call :ask || goto :quit
strictdoc export "%PROJECT%" --formats=json --output-dir exported-json
if not exist "exported-json\json\index.json" (
    echo.
    echo [ERROR] exported-json\json\index.json was not produced. Read the output above.
    goto :fail
)

rem ---------------------------------------------------------------------------
call :head 2 "A query kept in a .jq file" 02-jq-file.txt 01-open-findings-en.jq
echo    jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json
call :ask || goto :quit
jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json

rem ---------------------------------------------------------------------------
rem No carets before the pipes: inside the quotes of an echo, "^" is printed
rem literally, and the reader would copy a command that does not run.
call :head 3 "The same query written inline" 03-inline.txt
echo    jq -r ".DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS==\"Open\") | .UID + \"  \" + .TITLE" exported-json\json\index.json
call :ask || goto :quit
jq -r ".DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS==\"Open\") | .UID + \"  \" + .TITLE" exported-json\json\index.json

rem ---------------------------------------------------------------------------
call :head 4 "The search word kept inside the .jq file" 04-jq-file-kw.txt 04-keyword-en.jq
echo    jq -r -f jq-samples\04-keyword-en.jq exported-json\json\index.json
call :ask || goto :quit
jq -r -f jq-samples\04-keyword-en.jq exported-json\json\index.json

rem ---------------------------------------------------------------------------
rem The keyword comes from a file so that this step stays the mirror image of
rem the Japanese trial, where it has to. On the command line it is an ordinary
rem argument either way, which is the point.
set "KW="
set /p "KW="<"jq-samples\lesson-en\keyword.txt"
call :head 5 "The same word passed on the command line instead" 05-arg-kw.txt
echo    jq -r --arg kw %KW% "(the same filter as step 4, with contains($kw))" exported-json\json\index.json
call :ask || goto :quit
jq -r --arg kw "%KW%" ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"REQUIREMENT\") | select(((.TITLE // \"\") + (.STATEMENT // \"\")) | contains($kw)) | .UID + \"  \" + .TITLE" exported-json\json\index.json

rem ---------------------------------------------------------------------------
call :head 6 "Take the answer as JSON instead of text" 06-json-out.txt 03-findings-json.jq
echo    jq -f jq-samples\03-findings-json.jq exported-json\json\index.json
call :ask || goto :quit
jq -f jq-samples\03-findings-json.jq exported-json\json\index.json

rem ---------------------------------------------------------------------------
call :head 7 "Reshape the JSON file itself" 07-readable.txt
echo    jq . exported-json\json\index.json ^^> exported-json\readable.json
echo    jq -c . exported-json\json\index.json ^^> exported-json\min.json
call :ask || goto :quit
jq . exported-json\json\index.json > exported-json\readable.json
jq -c . exported-json\json\index.json > exported-json\min.json
echo  Sizes:
for %%F in (exported-json\json\index.json exported-json\readable.json exported-json\min.json) do @echo    %%~nxF  %%~zF bytes

rem ---------------------------------------------------------------------------
echo.
echo ============================================================
echo  Finished
echo ============================================================
echo.
type "jq-samples\lesson-en\99-end.txt"
echo.
goto :end

rem ---------------------------------------------------------------------------
rem %1 step number, %2 title, %3 lesson file, %4 optional .jq file to show.
:head
echo.
echo ============================================================
echo  Step %~1 / 7   %~2
echo ============================================================
echo.
type "jq-samples\lesson-en\%~3"
echo.
if not "%~4"=="" (
    echo  ---- jq-samples\%~4 ----
    type "jq-samples\%~4"
    echo  ----
    echo.
)
echo  Command:
exit /b 0

rem Returns 1 when the answer was q, so callers can write "call :ask || goto :quit".
:ask
set "ANS="
set /p "ANS=  [Enter] run   /   q [Enter] quit : "
echo.
if /i "%ANS%"=="q" exit /b 1
exit /b 0

:quit
echo  Stopped. What ran so far is in exported-json\.
goto :end

:fail
echo.
pause
endlocal & exit /b 1

:end
echo.
pause
endlocal & exit /b 0
