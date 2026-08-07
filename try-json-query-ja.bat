@echo off
rem StrictDocStarter - try-json-query-ja.bat
rem
rem A guided trial of chapter 4 of samples\md-basic-ja\01-guide-for-human.md: export the
rem whole project to JSON, then pull answers out of it with jq. Each step prints
rem an explanation, waits for Enter, and runs the command it just showed. Type q
rem at any prompt to stop.
rem
rem Drop a project folder on this file to use it; with none, the bundled
rem samples\md-basic-ja is used so the output matches the guide. JSON goes to
rem exported-json\ (git-ignored).
rem
rem Three things here are deliberate and easy to "fix" wrongly:
rem
rem 1. This file is pure ASCII and its Japanese lives in jq-samples\lesson-ja\
rem    *.txt, shown with "type". cmd.exe parses a batch file's bytes with the
rem    OEM code page whatever chcp says, so Japanese written in a UTF-8 .bat has
rem    its lines split mid-sentence and the tail runs as a command. Some lines
rem    survive and some do not, depending on byte alignment. "type" copies bytes
rem    through without parsing them.
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
set "PROJECT=%~dp0samples\md-basic-ja"
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
type "jq-samples\lesson-ja\00-intro.txt"
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
call :head 2 "A query in a .jq file, written in English" 02-jq-file-en.txt 01-open-findings-en.jq
echo    jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json
call :ask || goto :quit
jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json

rem ---------------------------------------------------------------------------
rem No carets before the pipes: inside the quotes of an echo, "^" is printed
rem literally, and the reader would copy a command that does not run.
call :head 3 "The same query written inline, in English" 03-inline-en.txt
echo    jq -r ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"FINDING\") | .UID + \"  \" + .TITLE" exported-json\json\index.json
call :ask || goto :quit
jq -r ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"FINDING\") | .UID + \"  \" + .TITLE" exported-json\json\index.json

rem ---------------------------------------------------------------------------
call :head 4 "A query in a .jq file, written in Japanese" 04-jq-file-ja.txt 02-keyword-ja.jq
echo    jq -r -f jq-samples\02-keyword-ja.jq exported-json\json\index.json
call :ask || goto :quit
jq -r -f jq-samples\02-keyword-ja.jq exported-json\json\index.json

rem ---------------------------------------------------------------------------
rem The keyword comes from a file because this one must stay ASCII. On the
rem command line it is an ordinary argument either way, which is the point.
set "KW="
set /p "KW="<"jq-samples\lesson-ja\keyword.txt"
call :head 5 "The same word passed on the command line instead" 05-arg-ja.txt
echo    jq -r --arg kw %KW% "(the same filter as step 4, with contains($kw))" exported-json\json\index.json
call :ask || goto :quit
jq -r --arg kw "%KW%" ".DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE==\"REQUIREMENT\") | select(((.TITLE // \"\") + (.STATEMENT // \"\")) | contains($kw)) | .UID + \"  \" + .TITLE" exported-json\json\index.json

rem ---------------------------------------------------------------------------
call :head 6 "Take the answer as JSON instead of text" 06-json-out.txt 03-findings-json.jq
echo    jq -f jq-samples\03-findings-json.jq exported-json\json\index.json
call :ask || goto :quit
jq -f jq-samples\03-findings-json.jq exported-json\json\index.json

rem ---------------------------------------------------------------------------
call :head 7 "Fix the Japanese inside the JSON file itself" 07-readable.txt
echo    jq . exported-json\json\index.json ^> exported-json\readable.json
echo    jq -c . exported-json\json\index.json ^> exported-json\min.json
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
type "jq-samples\lesson-ja\99-end.txt"
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
type "jq-samples\lesson-ja\%~3"
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
