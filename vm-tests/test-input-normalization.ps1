# StrictDocStarter - negative test for the input checks (FR-1169 / FR-1170).
#
# A clean run of the launcher proves nothing about these two checks: a project
# whose files are all UTF-8 and all LF exercises neither branch. So this builds a
# project that is broken in one specific way per case, and requires that the
# matching branch fires and that every other file is left alone.
#
# Six cases, each one a file a Windows editor really produces:
#
#   1. cp932 Markdown           -> named, and convertible (ANSI round-trips)
#   2. UTF-16 LE with a BOM     -> named, and convertible (the BOM is proof)
#   3. bytes nothing decodes    -> named, and NOT touched
#   4. UTF-8 CRLF Markdown      -> offered for LF, not reported as an encoding fault
#   5. CRLF .sdoc / .sgra       -> left alone (a different reader; carries no CR through)
#   6. anything under output\ or __pycache__\ -> never looked at
#
# Case 3 is the one that matters most. "This is not UTF-8" can be decided; "this
# is cp932" cannot, so a file that neither the BOM nor the ANSI code page
# explains must be reported and left as it is. A wrong guess destroys the text
# for good, while a failed export is something the author can still recover from.
#
# Non-ASCII text is built from byte values rather than written literally, so this
# file stays English ASCII (NFR-010) while still producing real cp932 content.
#
# Usage:
#     powershell -NoProfile -File vm-tests\test-input-normalization.ps1

[CmdletBinding()]
param([switch]$Keep)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

. (Join-Path $RepoRoot 'lib\server-config.ps1')

$script:Failures = 0

function Assert-True {
    param([Parameter(Mandatory)] [string]$Label, [Parameter(Mandatory)] [bool]$Condition)
    if ($Condition) {
        Write-Host "  ok    $Label"
    } else {
        Write-Host "  FAIL  $Label" -ForegroundColor Red
        $script:Failures++
    }
}

function Assert-Equal {
    param([Parameter(Mandatory)] [string]$Label, $Expected, $Actual)
    if ("$Expected" -eq "$Actual") {
        Write-Host "  ok    $Label"
    } else {
        Write-Host "  FAIL  $Label (expected '$Expected', got '$Actual')" -ForegroundColor Red
        $script:Failures++
    }
}

function New-Fixture {
    param([Parameter(Mandatory)] [string]$Root)

    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Root '_assets') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Root 'output\strictdoc\html') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Root '__pycache__') -Force | Out-Null

    $utf8 = New-Object System.Text.UTF8Encoding($false)

    # Clean: UTF-8, LF. Nothing must be offered for this one.
    [System.IO.File]::WriteAllText((Join-Path $Root '00-clean.md'), "# Clean`n`n**UID**: DOC-CLEAN`n", $utf8)

    # Case 4: UTF-8 with CRLF. An encoding check must not report it; the line
    # ending check must.
    [System.IO.File]::WriteAllText((Join-Path $Root '01-crlf.md'), "# Crlf`r`n`r`n**UID**: DOC-CRLF`r`n", $utf8)

    # Case 1: cp932. 0x82C4 0x82B7 is a pair of Japanese kana in code page 932,
    # and 0x82 is not a valid UTF-8 start byte.
    $cp932 = [byte[]](0x23, 0x20, 0x82, 0xC4, 0x82, 0xB7, 0x0D, 0x0A)
    [System.IO.File]::WriteAllBytes((Join-Path $Root '02-cp932.md'), $cp932)

    # Case 2: UTF-16 LE with a byte order mark.
    [System.IO.File]::WriteAllBytes((Join-Path $Root '03-utf16.md'),
        [System.Text.Encoding]::Unicode.GetPreamble() + [System.Text.Encoding]::Unicode.GetBytes("# Utf16`r`n"))

    # Case 3: not UTF-8, and not a clean round trip through code page 932 either
    # (0x80 and 0xA0 have no mapping there), so nothing explains these bytes.
    [System.IO.File]::WriteAllBytes((Join-Path $Root '04-unknown.md'),
        [byte[]](0x23, 0x20, 0x80, 0xA0, 0xFD, 0xFE, 0x0A))

    # Case 5: .sdoc and .sgra in CRLF. Left alone by both checks.
    [System.IO.File]::WriteAllText((Join-Path $Root '05-doc.sdoc'), "[DOCUMENT]`r`nTITLE: Doc`r`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $Root 'basic.sgra'), "[GRAMMAR]`r`nELEMENTS:`r`n", $utf8)

    # Case 6: generated output and Python cache. Both are broken on purpose; both
    # must be invisible to the checks.
    [System.IO.File]::WriteAllBytes((Join-Path $Root 'output\strictdoc\html\copy.md'), $cp932)
    [System.IO.File]::WriteAllBytes((Join-Path $Root '__pycache__\stale.md'), $cp932)

    # An attachment that is a document in its own right, to prove the walk is
    # recursive and reaches _assets\.
    [System.IO.File]::WriteAllText((Join-Path $Root '_assets\note.md'), "# Note`r`n", $utf8)
}

# ---------------------------------------------------------------- run

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("sdstarter-input-" + [System.Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Fixture -Root $root
Write-Host "fixture: $root"
Write-Host ""

Write-Host "byte level checks"
$utf8 = New-Object System.Text.UTF8Encoding($false)
Assert-True  "UTF-8 bytes read as UTF-8"        (Test-BytesAreUtf8 -Bytes $utf8.GetBytes("# ok`n"))
Assert-True  "an empty file reads as UTF-8"     (Test-BytesAreUtf8 -Bytes ([byte[]]@()))
Assert-True  "cp932 bytes do not"               (-not (Test-BytesAreUtf8 -Bytes ([byte[]](0x82, 0xC4))))
Assert-True  "a UTF-8 BOM is accepted"          (Test-BytesAreUtf8 -Bytes ($utf8.GetPreamble() + $utf8.GetBytes("# ok")))

$utf16 = Get-RecoverableEncoding -Bytes ([System.Text.Encoding]::Unicode.GetPreamble() + [System.Text.Encoding]::Unicode.GetBytes("x"))
Assert-Equal "a UTF-16 BOM identifies the file" "utf-16" ($(if ($utf16) { $utf16.WebName } else { '<null>' }))
$ansi = Get-RecoverableEncoding -Bytes ([byte[]](0x82, 0xC4, 0x82, 0xB7))
Assert-True  "cp932 round-trips through the ANSI code page" ($null -ne $ansi)
$none = Get-RecoverableEncoding -Bytes ([byte[]](0x80, 0xA0, 0xFD, 0xFE))
Assert-True  "bytes nothing explains stay unidentified"     ($null -eq $none)

Write-Host ""
Write-Host "walk"
$sources = Get-ProjectSourceFile -ProjectPath $root -Extension @('.md', '.sdoc', '.sgra')
$names = @($sources | ForEach-Object { $_.Name })
Assert-Equal "files found outside output\ and __pycache__\" 8 $names.Count
Assert-True  "_assets is walked"                            ($names -contains 'note.md')
Assert-True  "output\ is not"                               (-not ($sources | Where-Object { $_.FullName -like '*\output\*' }))
Assert-True  "__pycache__\ is not"                          (-not ($sources | Where-Object { $_.FullName -like '*__pycache__*' }))

Write-Host ""
Write-Host "encoding check (FR-1169)"
$found = Get-NonUtf8SourceFile -ProjectPath $root
$convertibleNames = @($found.Convertible | ForEach-Object { $_.File.Name })
$unknownNames = @($found.Unknown | ForEach-Object { $_.Name })
Assert-Equal "two files can be converted"       2 $convertibleNames.Count
Assert-True  "cp932 is one of them"             ($convertibleNames -contains '02-cp932.md')
Assert-True  "UTF-16 is the other"              ($convertibleNames -contains '03-utf16.md')
Assert-Equal "one file cannot be identified"    1 $unknownNames.Count
Assert-True  "and it is the undecodable one"    ($unknownNames -contains '04-unknown.md')
Assert-True  "a CRLF UTF-8 file is not an encoding fault" ($convertibleNames + $unknownNames -notcontains '01-crlf.md')

Write-Host ""
Write-Host "line ending check (FR-1170)"
$crlf = @(Get-CrlfMarkdownFile -ProjectPath $root | ForEach-Object { $_.Name })
Assert-True  "the CRLF Markdown is offered"     ($crlf -contains '01-crlf.md')
Assert-True  "the attachment is offered too"    ($crlf -contains 'note.md')
Assert-True  "the LF Markdown is not"           ($crlf -notcontains '00-clean.md')
Assert-True  ".sdoc is never offered"           ($crlf -notcontains '05-doc.sdoc')
Assert-True  ".sgra is never offered"           ($crlf -notcontains 'basic.sgra')
Assert-True  "a non-UTF-8 file is left to FR-1169" ($crlf -notcontains '02-cp932.md')

Write-Host ""
Write-Host "conversion"
$stamp = 'testrun'
$cp932Path = Join-Path $root '02-cp932.md'
$before = [System.IO.File]::ReadAllBytes($cp932Path)
Assert-True  "cp932 file converts"              (Convert-FileToUtf8 -Path $cp932Path -Encoding $ansi -Stamp $stamp)
Assert-True  "and is UTF-8 afterwards"          (Test-BytesAreUtf8 -Bytes ([System.IO.File]::ReadAllBytes($cp932Path)))
Assert-True  "the backup holds the old bytes"   (@(Compare-Object $before ([System.IO.File]::ReadAllBytes("$cp932Path.bak-$stamp"))).Count -eq 0)

$utf16Path = Join-Path $root '03-utf16.md'
[void](Convert-FileToUtf8 -Path $utf16Path -Encoding ([System.Text.Encoding]::Unicode) -Stamp $stamp)
$utf16Bytes = [System.IO.File]::ReadAllBytes($utf16Path)
Assert-True  "UTF-16 converts to UTF-8"         (Test-BytesAreUtf8 -Bytes $utf16Bytes)
Assert-True  "and keeps no byte order mark"     (-not ($utf16Bytes.Length -ge 3 -and $utf16Bytes[0] -eq 0xEF -and $utf16Bytes[1] -eq 0xBB -and $utf16Bytes[2] -eq 0xBF))

$crlfPath = Join-Path $root '01-crlf.md'
$crlfBefore = [System.IO.File]::ReadAllBytes($crlfPath)
Assert-True  "CRLF converts to LF"              (Convert-FileToLf -Path $crlfPath -Stamp $stamp)
Assert-True  "no CRLF is left"                  (@(Get-CrlfMarkdownFile -ProjectPath $root | Where-Object { $_.Name -eq '01-crlf.md' }).Count -eq 0)
Assert-True  "the backup holds the old bytes"   (@(Compare-Object $crlfBefore ([System.IO.File]::ReadAllBytes("$crlfPath.bak-$stamp"))).Count -eq 0)

$untouched = [System.IO.File]::ReadAllBytes((Join-Path $root '04-unknown.md'))
Assert-True  "the unidentified file was never written" (@(Compare-Object $untouched ([byte[]](0x23, 0x20, 0x80, 0xA0, 0xFD, 0xFE, 0x0A))).Count -eq 0)

Write-Host ""
Write-Host "remembering a no (FR-1170)"
$configPath = Join-Path $root 'server.config.json'
Write-FileUtf8NoBom -Path $configPath -Content '{ "port": 5111 }'
Assert-True  "nothing is remembered at first"   (-not (Test-LineEndingsDeclined -ConfigPath $configPath -ProjectPath $root))
Save-LineEndingsDecline -ConfigPath $configPath -ProjectPath $root
Assert-True  "a no is remembered"               (Test-LineEndingsDeclined -ConfigPath $configPath -ProjectPath $root)
Assert-True  "another project is not affected"  (-not (Test-LineEndingsDeclined -ConfigPath $configPath -ProjectPath (Join-Path $root '_assets')))
Assert-True  "the rest of the config survives"  (((Read-FileNoBom -Path $configPath) | ConvertFrom-Json).port -eq 5111)

Write-Host ""
Write-Host ("-" * 60)
if ($Keep) {
    Write-Host "fixture kept at $root"
} else {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
if ($script:Failures -gt 0) {
    Write-Host "FAIL: $($script:Failures) check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "PASS: every branch fired on the defect it is there to catch."
exit 0
