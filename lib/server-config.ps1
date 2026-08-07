# lib/server-config.ps1 - server.config.json gen / load / validate / editor launch.
# Functions: Initialize-ServerConfig, Get-ServerConfig, Open-EditorForConfig,
#            Expand-UserPlaceholdersInString.
# Spec: FR-201..213 (config management), FR-208 (Expand-UserPlaceholders).
# Output language: English ASCII only (per NFR-005 / ADR-008).
#
# NOTE: dot-sourced from launch-strictdoc.ps1 (not a module). Functions are
#       visible at the caller scope.

function Expand-UserPlaceholdersInString {
    # FR-208: replace <user> with $env:USERNAME.
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    return $Text -replace '<user>', $env:USERNAME
}

function Expand-PathPlaceholders {
    # Extended placeholder expansion. Supports:
    #   <user>          -> $env:USERNAME (FR-208)
    #   <starter_root>  -> absolute path of launch-strictdoc.bat's folder
    # The second placeholder lets server.config.template.json point at the
    # bundled samples (samples/sdoc-patterns) regardless of where the
    # user extracted the ZIP -- unzip and "press 1 to Start" just works.
    #
    # Note: use String.Replace() (literal, not regex) for $StarterRoot because
    # Windows paths contain backslashes which would be interpreted as escapes
    # by the -replace operator.
    param(
        [string]$Text,
        [string]$StarterRoot
    )
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    $expanded = $Text -replace '<user>', $env:USERNAME
    if (-not [string]::IsNullOrEmpty($StarterRoot)) {
        $expanded = $expanded.Replace('<starter_root>', $StarterRoot)
    }
    return $expanded
}

function Read-FileNoBom {
    param([Parameter(Mandatory)] [string]$Path)
    # Read UTF-8, strip BOM if present (FR-204 / Mi4).
    $raw = Get-Content -Raw -Encoding UTF8 -Path $Path -ErrorAction Stop
    if ($null -ne $raw -and $raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) {
        $raw = $raw.Substring(1)
    }
    return $raw
}

function Write-FileUtf8NoBom {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content
    )
    # Write UTF-8 without BOM (PowerShell 5.1 compatibility).
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Initialize-ServerConfig {
    param(
        [Parameter(Mandatory)] [string]$TemplatePath,
        [Parameter(Mandatory)] [string]$ConfigPath,
        [string]$StarterRoot = ''
    )
    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }
    # FR-201: copy template + expand placeholders + write UTF-8 BOM-less.
    # Placeholders: <user> (FR-208) and <starter_root> (samples auto-default).
    #
    # The template is JSON, so when substituting into the raw text we MUST
    # escape backslashes (Windows path separator) to \\ -- otherwise valid
    # Windows paths like 'C:\Users\good_' produce invalid JSON (\U is not a
    # valid JSON escape) and ConvertFrom-Json fails.
    $raw = Read-FileNoBom -Path $TemplatePath
    $userJson = $env:USERNAME
    $rootJson = if ([string]::IsNullOrEmpty($StarterRoot)) { '' } else { $StarterRoot.Replace('\', '\\') }
    $expanded = $raw.Replace('<user>', $userJson)
    if (-not [string]::IsNullOrEmpty($rootJson)) {
        $expanded = $expanded.Replace('<starter_root>', $rootJson)
    }
    Write-FileUtf8NoBom -Path $ConfigPath -Content $expanded
}

function New-ValidationResult {
    param(
        [bool]$Ok = $false,
        [string]$ErrorField = '',
        [string]$ErrorMessage = ''
    )
    return [pscustomobject]@{
        Ok           = $Ok
        ErrorField   = $ErrorField
        ErrorMessage = $ErrorMessage
    }
}

function Test-HostIsValid {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    $isIPv4  = $Value -match '^\d{1,3}(\.\d{1,3}){3}$'
    $isLocal = ($Value -eq 'localhost')
    # M6: IPv6 requires at least one ':' to avoid matching bare hex tokens
    # like 'a' or ':'. Common literals such as '::', '::1', 'fe80::1' all
    # contain at least one ':' and only hex/':' chars.
    $isIPv6  = ($Value -match '^[0-9a-fA-F:]+$') -and ($Value.Contains(':'))
    return ($isIPv4 -or $isLocal -or $isIPv6)
}

function Get-ServerConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [string]$StarterRoot = ''
    )

    $result = [pscustomobject]@{
        Config     = $null
        Validation = New-ValidationResult
    }

    if (-not (Test-Path $Path)) {
        $result.Validation = New-ValidationResult -ErrorField 'file' -ErrorMessage "config not found: $Path"
        return $result
    }

    # FR-204: read UTF-8, strip BOM, parse JSON.
    try {
        $raw = Read-FileNoBom -Path $Path
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $result.Validation = New-ValidationResult -ErrorField 'parse' -ErrorMessage "JSON parse failed: $($_.Exception.Message)"
        return $result
    }

    # FR-208: expand <user> + <starter_root> on path fields before any
    # Test-Path / Start-Process invocation.
    $projectPath = Expand-PathPlaceholders -Text $parsed.project_path -StarterRoot $StarterRoot
    $outputPath  = Expand-PathPlaceholders -Text $parsed.output_path  -StarterRoot $StarterRoot

    # Coerce port to int (template may store as JSON number, but defend against string).
    $portValue = 0
    if ($null -ne $parsed.port) {
        [int]::TryParse($parsed.port.ToString(), [ref]$portValue) | Out-Null
    }

    $openBrowser = $false
    if ($parsed.PSObject.Properties['open_browser']) {
        $openBrowser = [bool]$parsed.open_browser
    }

    $config = [pscustomobject]@{
        project_path = $projectPath
        host         = $parsed.host
        port         = $portValue
        open_browser = $openBrowser
        output_path  = $outputPath
    }
    $result.Config = $config

    # FR-210 (v1.2 / ADR-114): validation checks host/port only. project_path is OPTIONAL --
    # it is resolved at runtime from D&D / prompt (FR-1150 / FR-1153); the config value is only
    # the default offered at the prompt, so an empty/stale project_path must NOT fail config load.
    if (-not (Test-HostIsValid -Value $config.host)) {
        $result.Validation = New-ValidationResult -ErrorField 'host' -ErrorMessage "host must be IPv4, localhost, or IPv6 literal (got: $($config.host))"
        return $result
    }
    if ($config.port -lt 1025 -or $config.port -gt 64999) {
        $result.Validation = New-ValidationResult -ErrorField 'port' -ErrorMessage "port must be an integer in 1025..64999 (got: $($config.port))"
        return $result
    }
    # open_browser: any value coerces to bool; no further check.
    # output_path: optional, no existence check (strictdoc will create).

    $result.Validation = New-ValidationResult -Ok $true
    return $result
}

function Open-EditorForConfig {
    param([Parameter(Mandatory)] [string]$Path)
    # FR-202 / FR-212: 'code' (with HasExited check) -> 'notepad' fallback.

    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $eap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $proc = Start-Process -FilePath code -ArgumentList '--reuse-window', $Path -PassThru -ErrorAction Stop
            Start-Sleep -Seconds 1
            if ($null -ne $proc -and $proc.HasExited -and $proc.ExitCode -ne 0) {
                Write-Host "[INFO] 'code' exited with non-zero (code $($proc.ExitCode)). Falling back to notepad."
            } else {
                $ErrorActionPreference = $eap
                return
            }
        } catch {
            Write-Host "[INFO] 'code' launch failed: $($_.Exception.Message). Falling back to notepad."
        }
        $ErrorActionPreference = $eap
    }
    try {
        Start-Process -FilePath notepad -ArgumentList $Path -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "[ERROR] Failed to launch any editor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-IsDriveOrShareRoot {
    # FR-1151c: reject a drive root (C:\) or UNC share root (\\server\share) so we never
    # scan a whole drive/share. A normal folder beneath them (\\server\share\proj) is fine.
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    # Raw form first: bare 'C:' / 'C:\' must be caught BEFORE GetFullPath, which would turn
    # bare 'C:' into the current dir on that drive (and silently serve it).
    if ($Path.TrimEnd('\', '/') -match '^[A-Za-z]:$') { return $true }
    $full = $null
    try { $full = [System.IO.Path]::GetFullPath($Path) } catch { return $false }
    $trimmed = $full.TrimEnd('\', '/')
    if ($trimmed -match '^[A-Za-z]:$') { return $true }                 # C: (drive root)
    if ($full -match '^\\\\[^\\]+\\[^\\]+\\?$') { return $true }        # \\server\share (share root)
    return $false
}

function Resolve-ProjectPathFromInput {
    # FR-1150b / FR-1151 / FR-1152 / FR-1153 / FR-1154: resolve project_path from dropped
    # paths (D&D) or an interactive prompt. Returns an absolute folder path, or $null on cancel.
    param(
        [string[]]$DroppedPaths = @(),
        [string]$DefaultPath = ''
    )
    # FR-1152: multiple items dropped -> use the first only.
    $candidate = $null
    $dropped = @($DroppedPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($dropped.Count -gt 0) {
        if ($dropped.Count -gt 1) {
            Write-Host "[WARN]  Multiple items dropped; using the first: $($dropped[0])" -ForegroundColor Yellow
        }
        $candidate = $dropped[0]
    }

    while ($true) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            # FR-1153: prompt (no drop, or previous candidate rejected).
            $defaultShown = if ([string]::IsNullOrWhiteSpace($DefaultPath)) { '(none)' } else { $DefaultPath }
            $answer = Read-Host "Enter folder path (or Q to quit) [default: $defaultShown]"
            $answer = "$answer".Trim().Trim('"').Trim("'")
            if ($answer -eq 'Q' -or $answer -eq 'q') {       # FR-1153c
                Write-Host "[INFO]  Cancelled."
                return $null
            }
            if ([string]::IsNullOrWhiteSpace($answer)) {     # FR-1153a: Enter = default
                if ([string]::IsNullOrWhiteSpace($DefaultPath)) {
                    Write-Host "[WARN]  No default available. Enter a folder path or Q to quit." -ForegroundColor Yellow
                    continue
                }
                $candidate = $DefaultPath
            } else {
                $candidate = $answer
            }
        }

        # FR-1151d: .lnk shortcuts are not supported.
        if ($candidate -match '(?i)\.lnk$') {
            Write-Host "[WARN]  Shortcuts (.lnk) are not supported; drop the actual folder/file." -ForegroundColor Yellow
            $candidate = $null
            continue
        }

        $resolved = $candidate
        try { $resolved = [System.IO.Path]::GetFullPath($candidate) } catch {}

        # FR-1151b: a file resolves to its parent folder.
        if (Test-Path -LiteralPath $resolved -PathType Leaf) {
            $resolved = Split-Path -Parent $resolved
        }

        # FR-1151c: reject drive / UNC share root. Check the RAW candidate too, so a bare
        # 'C:' typed at the prompt is rejected (GetFullPath would otherwise resolve it to CWD).
        if ((Test-IsDriveOrShareRoot -Path $candidate) -or (Test-IsDriveOrShareRoot -Path $resolved)) {
            Write-Host "[ERROR] '$resolved' is a drive/share root. Drop a project folder, not a whole drive." -ForegroundColor Red
            $candidate = $null
            continue
        }

        # FR-1154a: must exist and be a directory.
        if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
            Write-Host "[ERROR] $resolved does not exist or is not a usable project folder." -ForegroundColor Red
            $candidate = $null
            continue
        }

        # FR-1154b: warn (non-fatal) when the folder holds no documents at all.
        # Count .md as well as .sdoc -- StrictDoc reads both, and the bundled
        # md-basic-ja sample has no .sdoc whatsoever, so a .sdoc-only test called
        # a perfectly good project empty. Search recursively for the same reason:
        # documents commonly sit in a docs\ subfolder. The output folder is skipped
        # so a previous run's copies never count as content.
        $docs = @(
            Get-ChildItem -LiteralPath $resolved -Include *.sdoc, *.md -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '(?i)\\output\\' }
        )
        if ($docs.Count -eq 0) {
            Write-Host "[WARN]  No .sdoc or .md files found under $resolved. Starting as an empty project." -ForegroundColor Yellow
        }

        return $resolved
    }
}

function Save-LastUsedProjectPath {
    # FR-1155: persist the resolved project_path into server.config.json (last-used = next
    # default). host / port / open_browser / output_path are preserved. UTF-8 no BOM.
    # Non-fatal on failure (FR-1155c).
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$ProjectPath
    )
    try {
        $raw = Read-FileNoBom -Path $ConfigPath
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
        if ($obj.PSObject.Properties['project_path']) {
            $obj.project_path = $ProjectPath
        } else {
            $obj | Add-Member -NotePropertyName project_path -NotePropertyValue $ProjectPath -Force
        }
        $json = $obj | ConvertTo-Json -Depth 10
        # PS 5.1 ConvertTo-Json HTML-escapes > < ' & inside string values; the only docs for
        # this no-menu tool are the _comment_* fields, so restore readability. All four are
        # safe to leave literal in a JSON string.
        $json = $json -replace '\\u003e', '>' -replace '\\u003c', '<' -replace '\\u0027', "'" -replace '\\u0026', '&'
        Write-FileUtf8NoBom -Path $ConfigPath -Content $json
    } catch {
        Write-Host "[WARN]  Could not save last-used path: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Project config: scaffolding (FR-1142..1145) and generation upgrade (FR-1163).
# ---------------------------------------------------------------------------

# Bump this whenever the scaffolded body changes in a way the user would see,
# and add the previous body's normalised SHA-256 to $script:LegacyScaffoldHashes
# in the same commit. A body whose only difference is this stamp does NOT need a
# bump: nothing user-visible changes, so there is nothing to ask about.
$script:ScaffoldVersion = 4

# Normalised SHA-256 of every scaffold body this launcher has written that is
# now out of date. A file matching one of these was written by us and has not
# been edited since, so replacing it cannot lose anyone's work. Anything else is
# hand-written or edited and is never overwritten (FR-1142).
#
# Two kinds of digest live in here, and Test-ScaffoldBodyIsOurs looks both up.
# Generations 1..3 wrote a fixed project_title, so their digest is of the body
# exactly as written. From generation 4 on the title is the project folder's
# name (FR-1167), which would give a different digest in every folder, so those
# digests are taken with the title value masked out (Get-ScaffoldIdentityHash).
$script:LegacyScaffoldHashes = @{
    '01d9ebb363d36441a237fd6b13a48036b11c178c2a54b553d1a8be5afb80b0b8' = $true
    '0376451f9f270939c35433871aa3393511565ae24a39a627cec45295245182e8' = $true
    '33ae2fbab597fb3c96bf9aa6d3ae05a809db16a63a57111290176b5d189ecf94' = $true
    '5abdb31a259a16e27dba24cd189cb55c4fcd9b24fc693fc01e05e6ac6a9636ae' = $true
    # Generation 3, title masked. Covers both the file as we wrote it and one
    # whose title was later changed from the browser (strictdoc 0.21.1+ rewrites
    # exactly this one value), so a renamed project can still be offered an
    # update instead of being written off as hand-edited.
    'de86969d83e7772a554a6add37a209e67ba87a81ebb0241a80acaa631ad6dc5a' = $true
}

# Some generations add something that is not a project_features entry. Listing it
# here keeps the confirmation prompt from rendering an empty change list when the
# feature set happens to be unchanged.
$script:ScaffoldChangeNotes = @(
    'Colour mode: change-color-mode.bat can switch this project between light and dark',
    'Project title: new projects are named after their own folder, so several projects open at once stay apart'
)

# Titles nobody chose: the fixed string generations 1..3 wrote, and the one
# strictdoc falls back to on its own. A generation update replaces these with the
# project folder's name; any other title was picked by a person and is kept
# (FR-1167).
$script:PlaceholderProjectTitles = @(
    'StrictDoc Project',
    'Untitled Project'
)

# Used when no folder name can be derived (a drive or share root). FR-1151c
# rejects those before we get here, but a scaffold must never be written with an
# empty title.
$script:FallbackProjectTitle = 'StrictDoc Project'

# Name of the per-project stylesheet referenced by custom_css_path in the
# scaffold. Kept constant on purpose: the path has to be relative to the project
# folder, and a constant string keeps every scaffolded config byte-identical, so
# the hash check above still recognises our own output.
$script:ThemeCssFileName = 'strictdoc-theme.css'
$script:ThemeCssMarker   = 'Generated by StrictDocStarter'

# Features that put an icon in the left toolbar under `strictdoc server`, which
# is how this launcher always runs. The project index icon is always present and
# is counted on top of these.
$script:ToolbarIconFeatures = @(
    'PROJECT_STATISTICS_SCREEN',
    'TRACEABILITY_MATRIX_SCREEN',
    'TREE_MAP_SCREEN',
    'REQUIREMENT_TO_SOURCE_TRACEABILITY',
    'SEARCH',
    'DIFF'
)

# Plain-language names so the confirmation prompt can talk about screens rather
# than about Python identifiers. The audience for that prompt does not read
# Python (FR-1163).
$script:FeatureDisplayNames = @{
    'PROJECT_STATISTICS_SCREEN'  = 'Project statistics screen (left toolbar)'
    'TRACEABILITY_MATRIX_SCREEN' = 'Traceability matrix screen (left toolbar)'
    'TREE_MAP_SCREEN'            = 'Tree map screen (left toolbar)'
    'REQUIREMENT_TO_SOURCE_TRACEABILITY' = 'Source coverage screen (left toolbar)'
    'TABLE_SCREEN'               = 'Table view (per document)'
    'TRACEABILITY_SCREEN'        = 'Traceability view (per document)'
    'DEEP_TRACEABILITY_SCREEN'   = 'Deep traceability view (per document)'
    'SEARCH'                     = 'Search'
    'MATHJAX'                    = 'MathJax setting (on by default since strictdoc 0.27; listing it prints a deprecation warning)'
    'MERMAID'                    = 'Mermaid setting (on by default since strictdoc 0.27; listing it prints a deprecation warning)'
}

function Get-NormalizedConfigHash {
    # The scaffold body travels inside a here-string, so the bytes written follow
    # the line endings of this .ps1 in whatever checkout produced it. Normalise
    # first (strip BOM, CRLF -> LF, trim trailing whitespace per line, exactly one
    # trailing newline) so the digest depends on content alone.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)

    $t = $Text.TrimStart([char]0xFEFF)
    $t = $t -replace "`r`n", "`n"
    $t = $t -replace "`r", "`n"
    $lines = @($t -split "`n" | ForEach-Object { $_.TrimEnd() })
    $last = $lines.Count - 1
    while ($last -ge 0 -and $lines[$last] -eq '') { $last-- }
    if ($last -lt 0) { $normalised = "`n" } else { $normalised = (($lines[0..$last]) -join "`n") + "`n" }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalised)
        return (-join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }))
    } finally {
        $sha.Dispose()
    }
}

# One place that knows what a project_title assignment looks like. The value may
# be quoted either way, which is why the quote is captured and back-referenced.
$script:ProjectTitlePattern = 'project_title\s*=\s*(["''])(.*?)\1'

function Get-TitleMaskedConfigText {
    # Replace the project_title VALUE with a fixed placeholder. Used only for
    # hashing, never written to disk.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    return ($Text -replace $script:ProjectTitlePattern, 'project_title="__PROJECT_TITLE__"')
}

function Get-ScaffoldIdentityHash {
    # Digest that identifies one GENERATION of the scaffold rather than one file.
    #
    # Since FR-1167 the scaffolded project_title is the project folder's name, so
    # hashing the file as written would give a different digest in every folder
    # and "is this still the body we wrote?" could never be answered again.
    # Masking that one value fixes that, and has a second wanted effect: strictdoc
    # itself rewrites exactly this value when the project title is edited from the
    # Project Index screen (0.21.1+), so a renamed project is still recognisably
    # ours.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    return Get-NormalizedConfigHash -Text (Get-TitleMaskedConfigText -Text $Text)
}

function Test-ScaffoldBodyIsOurs {
    # True when this text is a scaffold body some generation of this launcher
    # wrote and nobody has edited since. See $script:LegacyScaffoldHashes for why
    # two digests are consulted.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    if ($script:LegacyScaffoldHashes.ContainsKey((Get-NormalizedConfigHash -Text $Text))) { return $true }
    return $script:LegacyScaffoldHashes.ContainsKey((Get-ScaffoldIdentityHash -Text $Text))
}

function Get-ProjectTitleFromText {
    # The configured title, or '' when the file does not set one at all.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    if ($Text -match $script:ProjectTitlePattern) { return $Matches[2] }
    return ''
}

function Test-ConfigDeclaresProjectTitle {
    # FR-1167: the mere presence of the words settles it. What the title says is
    # not our business -- someone who typed project_title="Untitled Project" on
    # purpose gets to keep it. A plain substring test cannot misfire the way a
    # value test could.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    return ($Text -match 'project_title')
}

function ConvertTo-PythonStringLiteral {
    # Escape text for the inside of a Python "..." literal.
    #
    # Measured: Windows will not create a folder whose name contains " or \ --
    # New-Item raises ArgumentException -- so a real folder name never needs this.
    # It stays because an unescaped quote would write a strictdoc_config.py that
    # Python cannot parse, and that stops the server before it starts; a caller
    # can also pass a title that came from somewhere other than a folder name.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    $escaped = $Text.Replace('\', '\\').Replace('"', '\"')
    # Control characters cannot occur in a Windows path, but never emit one:
    # it would end the literal mid-line.
    return ($escaped -replace '[\x00-\x1f]', '')
}

function Get-ProjectTitleFromPath {
    # FR-1167: name the project after its own folder.
    #
    # strictdoc already treats that name as this project's identifier -- its HTML
    # goes to <output>\html\<folder name>\ -- so the launcher is not inventing a
    # naming rule of its own. The fixed string used through generation 3 put the
    # same title on every tab, which made several projects open at once
    # indistinguishable, and left nothing behind if the config was deleted.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$ProjectPath)

    if ([string]::IsNullOrWhiteSpace($ProjectPath)) { return $script:FallbackProjectTitle }

    # Raw form first, before GetFullPath: it turns a bare 'C:' into the CURRENT
    # directory on that drive, and we would name the project after a folder the
    # user never pointed at. Same order, same reason, as Test-IsDriveOrShareRoot.
    if ($ProjectPath.TrimEnd('\', '/') -match '^[A-Za-z]:$') { return $script:FallbackProjectTitle }

    # GetFullPath settles '..' and a trailing separator. It throws on characters
    # Windows does not allow in a path at all, and rather than lose the name over
    # that, fall back to the text as given.
    $full = $ProjectPath
    try { $full = [System.IO.Path]::GetFullPath($ProjectPath) } catch { $full = $ProjectPath }
    $trimmed = $full.TrimEnd('\', '/')

    # And again after resolving, since GetFullPath can produce a drive root from
    # something that did not look like one ('C:\proj\..').
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed -match '^[A-Za-z]:$') {
        return $script:FallbackProjectTitle
    }

    # Cut the last segment textually rather than with Split-Path, which resolves a
    # bare 'C:' against the CURRENT directory on that drive. Measured:
    # Split-Path -Leaf 'C:' returned 'StrictDocStarter' with the working directory
    # set to the repo -- a folder the user never pointed at.
    $leaf = $trimmed.Substring($trimmed.LastIndexOfAny(@([char]'\', [char]'/')) + 1)
    if ([string]::IsNullOrWhiteSpace($leaf)) { return $script:FallbackProjectTitle }
    return $leaf
}

function Get-ProjectFeatureList {
    # Pull the project_features entries out of a strictdoc_config.py. Commented
    # out entries do not count: they are not active.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)

    $features = New-Object System.Collections.Generic.List[string]
    $inBlock = $false
    foreach ($line in ($Text -split "`r?`n")) {
        if (-not $inBlock) {
            if ($line -match 'project_features\s*=\s*\[') { $inBlock = $true }
            continue
        }
        if ($line -match '^\s*\]') { break }
        if ($line -match '^\s*#') { continue }
        if ($line -match '"([A-Z0-9_]+)"') { $features.Add($Matches[1]) }
    }
    return $features.ToArray()
}

function Get-ToolbarIconCount {
    # Icons visible in the left toolbar under `strictdoc server`.
    param([string[]]$Features)

    $count = 1  # project index: always shown
    foreach ($feature in $script:ToolbarIconFeatures) {
        if ($Features -contains $feature) { $count++ }
    }
    return $count
}

function Get-ScaffoldBody {
    # -ProjectPath supplies the project title (FR-1167). -Title overrides it, which
    # is how a generation update keeps a title someone chose for themselves.
    param(
        [string]$ProjectPath = '',
        [string]$Title = ''
    )
    $body = @'
# StrictDoc project configuration scaffolded by StrictDocStarter (launch-strictdoc).
# StrictDocStarter scaffold version: __SCAFFOLD_VERSION__
#
# Placed in this project folder so `strictdoc server <this folder>` enables the features
# below. StrictDoc reads the config from the input folder itself, not parent folders
# (verified on strictdoc 0.27.1). Shape follows the official `strictdoc new` output
# (create_config() returning a ProjectConfig). MATHJAX and MERMAID are deliberately NOT
# listed: strictdoc 0.27 and newer enable both by default and print a DEPRECATION warning
# if they are listed. Diagrams and math work without them.
#
# StrictDocStarter never overwrites a config you wrote yourself. It offers to update this
# one only while it is still byte-for-byte what the launcher generated; edit anything here
# and it becomes yours, and the launcher will only ever print suggestions from then on.
#
# Docs: https://strictdoc.readthedocs.io/
from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        # The name of this folder. Change it to whatever you want the project to
        # be called; it is the heading on the project index and the browser tab
        # title. StrictDoc can also change it for you: open the project index and
        # use the title's edit button.
        project_title="__PROJECT_TITLE__",
        # Appearance. StrictDoc has no dark mode of its own, so StrictDocStarter
        # supplies one as an extra stylesheet. The file next to this one is
        # rewritten every time the project is opened, following the color_mode
        # setting in server.config.json -- use change-color-mode.bat to change it.
        # The path must stay relative: strictdoc asserts on an absolute one.
        custom_css_path="strictdoc-theme.css",
        project_features=[
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "DEEP_TRACEABILITY_SCREEN",
            "SEARCH",
            # The three below are what put icons in the left toolbar; the four
            # above do not. TABLE / TRACEABILITY / DEEP_TRACEABILITY only add
            # entries to a document's VIEWS dropdown, and SEARCH's icon needs a
            # running server (nav.jinja.html and is_activated_search() both
            # require is_running_on_server) -- which is exactly how this
            # launcher runs, so SEARCH does show here even though a static
            # export never shows it.
            #
            # DIFF is deliberately NOT listed even though it, too, would get an
            # icon under the server. Its screen resolves the two Git revisions
            # in the server process's CURRENT WORKING DIRECTORY, not in the
            # served project folder, and this launcher starts strictdoc from the
            # StrictDocStarter folder. Measured on 0.27.1: from a non-Git
            # directory every revision comes back HTTP 422, and from a Git one
            # the screen quietly diffs THAT repository. If you want it, run
            # `strictdoc server .` yourself from inside your Git project.
            #
            # Cost of the three screens is small: about +0.5 s of export time.
            # TREE_MAP_SCREEN is the one that grows the output folder (it
            # bundles plotly.js -- a few MB on a large project).
            "PROJECT_STATISTICS_SCREEN",
            "TRACEABILITY_MATRIX_SCREEN",
            "TREE_MAP_SCREEN",
        ],
    )
'@
    $resolvedTitle = $Title
    if ([string]::IsNullOrWhiteSpace($resolvedTitle)) {
        $resolvedTitle = Get-ProjectTitleFromPath -ProjectPath $ProjectPath
    }
    return $body.Replace('__SCAFFOLD_VERSION__', $script:ScaffoldVersion.ToString()).
                 Replace('__PROJECT_TITLE__', (ConvertTo-PythonStringLiteral -Text $resolvedTitle))
}

function Get-ColorMode {
    # FR-1162. Anything unrecognised reads as 'auto': a typo should give the
    # recommended behaviour rather than an error on the launch path.
    param([Parameter(Mandatory)] [string]$ConfigPath)
    try {
        $obj = (Read-FileNoBom -Path $ConfigPath) | ConvertFrom-Json -ErrorAction Stop
        $value = "$($obj.color_mode)".Trim().ToLowerInvariant()
        if ($value -eq 'light' -or $value -eq 'dark' -or $value -eq 'auto') { return $value }
    } catch { }
    return 'auto'
}

function Save-ColorMode {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [ValidateSet('auto', 'light', 'dark')] [string]$Mode
    )
    try {
        $obj = (Read-FileNoBom -Path $ConfigPath) | ConvertFrom-Json -ErrorAction Stop
        $obj | Add-Member -NotePropertyName color_mode -NotePropertyValue $Mode -Force
        $json = $obj | ConvertTo-Json -Depth 10
        $json = $json -replace '\\u003e', '>' -replace '\\u003c', '<' -replace '\\u0027', "'" -replace '\\u0026', '&'
        Write-FileUtf8NoBom -Path $ConfigPath -Content $json
        return $true
    } catch {
        Write-Host "[ERROR] Could not save the colour mode: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-ThemeCssContent {
    # Build the stylesheet for one project. "light" still produces a file: the
    # scaffolded config names it, and strictdoc refuses to start if custom_css_path
    # points at something that does not exist.
    param(
        [Parameter(Mandatory)] [string]$Mode,
        [Parameter(Mandatory)] [string]$StarterRoot
    )
    $header = "/* $($script:ThemeCssMarker) (change-color-mode.bat). Colour mode: $Mode." + "`n" +
              " * Rewritten every time this project is opened. Edit assets\theme-dark.css" + "`n" +
              " * in the StrictDocStarter folder if you want different colours." + "`n" +
              " */" + "`n"

    if ($Mode -eq 'light') {
        return $header + "`n/* Light: StrictDoc's own appearance. No overrides needed. */`n"
    }

    $core = ''
    $source = Join-Path $StarterRoot 'assets\theme-dark.css'
    if (Test-Path -LiteralPath $source) {
        try { $core = Read-FileNoBom -Path $source } catch { $core = '' }
    }
    if ([string]::IsNullOrWhiteSpace($core)) {
        return $header + "`n/* assets\theme-dark.css was not found; leaving the default appearance. */`n"
    }

    if ($Mode -eq 'dark') { return $header + "`n" + $core }

    # auto: same rules, but only when the OS asks for a dark appearance.
    $indented = (($core -split "`r?`n") | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace($_)) { '' } else { "  $_" }
    }) -join "`n"
    return $header + "`n@media (prefers-color-scheme: dark) {`n" + $indented + "`n}`n"
}

function Update-ProjectTheme {
    # FR-1162: keep <project>\strictdoc-theme.css in step with color_mode, but only
    # for projects whose config actually asks for it, and only while the file is
    # still ours. A stylesheet someone wrote themselves is left alone.
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [string]$StarterRoot,
        [Parameter(Mandatory)] [string]$Mode
    )
    $cfgPy = Join-Path $ProjectPath 'strictdoc_config.py'
    if (-not (Test-Path -LiteralPath $cfgPy)) { return }
    try {
        if ((Read-FileNoBom -Path $cfgPy) -notmatch [regex]::Escape($script:ThemeCssFileName)) { return }
    } catch { return }

    $themePath = Join-Path $ProjectPath $script:ThemeCssFileName
    if (Test-Path -LiteralPath $themePath) {
        try {
            if ((Read-FileNoBom -Path $themePath) -notmatch [regex]::Escape($script:ThemeCssMarker)) {
                return   # someone replaced it with their own; leave it be
            }
        } catch { return }
    }

    try {
        Write-FileUtf8NoBom -Path $themePath -Content (Get-ThemeCssContent -Mode $Mode -StarterRoot $StarterRoot)
    } catch {
        # Non-fatal, but the config names this file, so say so: strictdoc will
        # refuse to start if it is missing entirely.
        Write-Host "[WARN]  Could not write $($script:ThemeCssFileName): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Get-DeclineKey {
    param([Parameter(Mandatory)] [string]$ProjectPath)
    try {
        return ([System.IO.Path]::GetFullPath($ProjectPath)).TrimEnd('\', '/').ToLowerInvariant()
    } catch {
        return $ProjectPath.ToLowerInvariant()
    }
}

function Test-ConfigUpgradeDeclined {
    # FR-1163: a project that said no is not asked again for the same version.
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$ProjectPath
    )
    try {
        if (-not (Test-Path -LiteralPath $ConfigPath)) { return $false }
        $obj = (Read-FileNoBom -Path $ConfigPath) | ConvertFrom-Json -ErrorAction Stop
        $map = $obj.PSObject.Properties['config_upgrade_declined']
        if (-not $map -or $null -eq $map.Value) { return $false }
        $key = Get-DeclineKey -ProjectPath $ProjectPath
        $entry = $map.Value.PSObject.Properties | Where-Object { $_.Name.ToLowerInvariant() -eq $key }
        if (-not $entry) { return $false }
        return ([int]$entry.Value -ge $script:ScaffoldVersion)
    } catch {
        return $false
    }
}

function Save-ConfigUpgradeDecline {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$ProjectPath
    )
    try {
        $obj = (Read-FileNoBom -Path $ConfigPath) | ConvertFrom-Json -ErrorAction Stop
        if (-not $obj.PSObject.Properties['config_upgrade_declined'] -or $null -eq $obj.config_upgrade_declined) {
            $obj | Add-Member -NotePropertyName config_upgrade_declined -NotePropertyValue (New-Object PSObject) -Force
        }
        $key = Get-DeclineKey -ProjectPath $ProjectPath
        $obj.config_upgrade_declined | Add-Member -NotePropertyName $key -NotePropertyValue $script:ScaffoldVersion -Force
        $json = $obj | ConvertTo-Json -Depth 10
        $json = $json -replace '\\u003e', '>' -replace '\\u003c', '<' -replace '\\u0027', "'" -replace '\\u0026', '&'
        Write-FileUtf8NoBom -Path $ConfigPath -Content $json
    } catch {
        Write-Host "[WARN]  Could not remember your answer: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Add-ProjectTitleLine {
    # Return $Text with one project_title line added inside the ProjectConfig(...)
    # call, or $null when there is no place to put it that is certainly safe.
    #
    # Only a ProjectConfig( that ends its line is accepted. Written on one line
    # -- ProjectConfig(project_title=..., ...) -- an inserted line would land
    # outside the call and break the file, and a config this launcher must not
    # own is the last place to guess.
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Text,
        [Parameter(Mandatory)] [string]$Title
    )

    # PowerShell variable names are case-insensitive, so this must not be called
    # anything a nearby name differs from only in case.
    $lineEnding = if ($Text -match "`r`n") { "`r`n" } else { "`n" }
    $lines = @($Text -split "`r?`n")

    $openIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*(?:return\s+)?ProjectConfig\(\s*$') { $openIndex = $i; break }
    }
    if ($openIndex -lt 0) { return $null }

    # Copy the indentation of the first argument already in the call, so the new
    # line matches whatever style the file uses (spaces, tabs, width). With no
    # argument to copy, indent one step past the opening line.
    $indent = $null
    for ($i = $openIndex + 1; $i -lt $lines.Count; $i++) {
        if ([string]::IsNullOrWhiteSpace($lines[$i])) { continue }
        if ($lines[$i] -match '^(\s*)\S') { $indent = $Matches[1] }
        break
    }
    if ($null -eq $indent) {
        $openIndent = ''
        if ($lines[$openIndex] -match '^(\s*)') { $openIndent = $Matches[1] }
        $indent = $openIndent + '    '
    }

    $titleLine = '{0}project_title="{1}",' -f $indent, (ConvertTo-PythonStringLiteral -Text $Title)
    $head = @($lines[0..$openIndex])
    # PowerShell ranges count backwards when the start exceeds the end, so an
    # opening line with nothing after it needs the empty case spelled out.
    $tail = if ($openIndex -ge ($lines.Count - 1)) { @() } else { @($lines[($openIndex + 1)..($lines.Count - 1)]) }
    return (($head + @($titleLine) + $tail) -join $lineEnding)
}

function Invoke-ProjectTitlePrompt {
    # FR-1168: a config we must not own that sets no project_title at all. Adding
    # the line silently would break FR-1163's promise never to touch someone
    # else's file, so show the exact change and ask.
    #
    # This is worth asking about twice over. Without the line strictdoc titles the
    # project "Untitled Project" without a word of warning, AND its own rename
    # button refuses to work: save_project_title rewrites an existing value with a
    # regex and answers HTTP 400 when there is none to rewrite.
    param(
        [Parameter(Mandatory)] [string]$ProjectConfigPath,
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$CurrentText
    )

    if (Test-ConfigDeclaresProjectTitle -Text $CurrentText) { return }

    $title = Get-ProjectTitleFromPath -ProjectPath $ProjectPath
    $newText = Add-ProjectTitleLine -Text $CurrentText -Title $title
    if ($null -eq $newText) {
        Write-Host ""
        Write-Host "[INFO]  This project's settings file does not set a project title, so every"
        Write-Host "        screen will say 'Untitled Project'. Add this line inside ProjectConfig(...):"
        Write-Host ('            project_title="{0}",' -f (ConvertTo-PythonStringLiteral -Text $title))
        Write-Host "        File: $ProjectConfigPath"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "[INFO]  This project's settings file does not say what the project is called."
    Write-Host "        StrictDoc then titles every screen 'Untitled Project', and its own"
    Write-Host "        rename button will not work because it has no title to rewrite."
    Write-Host ""
    Write-Host ("        Suggested title:  {0}   (this folder's name)" -f $title)
    Write-Host ""
    Write-Host "        Before:"
    Write-Host "            return ProjectConfig("
    Write-Host "        After:"
    Write-Host "            return ProjectConfig("
    Write-Host ('          +     project_title="{0}",' -f (ConvertTo-PythonStringLiteral -Text $title)) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "        One line is added. Nothing else in the file changes, and your documents"
    Write-Host "        are not touched:"
    Write-Host "          $ProjectConfigPath"
    Write-Host "        A backup is written first, in the same folder."
    Write-Host ""

    if (-not [Environment]::UserInteractive) {
        Write-Host "[INFO]  Not an interactive session; leaving the settings file as it is."
        return
    }

    # Two answers, and only one of them writes. This file is not the launcher's to
    # change, so pressing Enter -- or typing anything else -- must be completely
    # safe. There is no third "stop asking" answer on purpose: anyone who wants
    # the question to go away can put any project_title of their own in the file,
    # and FR-1167 then leaves it alone for good without reading the value. The
    # message below says so, so the way out is on screen rather than in a setting.
    Write-Host "        Type  yes  and press Enter to add the line."
    Write-Host "        Press Enter on its own to leave the file alone."
    Write-Host ""
    $reply = "$(Read-Host 'Add that line now?')".Trim().ToLowerInvariant()

    if ($reply -ne 'yes' -and $reply -ne 'y') {
        Write-Host "[INFO]  Nothing was changed."
        Write-Host "        Prefer to pick the title yourself? Put any project_title line inside"
        Write-Host "        ProjectConfig(...) -- once one is there, this is never asked again:"
        Write-Host ('            project_title="{0}",' -f (ConvertTo-PythonStringLiteral -Text $title))
        return
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$ProjectConfigPath.bak-$stamp"
    try {
        Copy-Item -LiteralPath $ProjectConfigPath -Destination $backupPath -ErrorAction Stop
        Write-FileUtf8NoBom -Path $ProjectConfigPath -Content $newText
        Write-Host "[INFO]  Added. Backup saved as $(Split-Path -Leaf $backupPath)."
    } catch {
        Write-Host "[WARN]  Could not update the settings file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Show-ProjectConfigSuggestion {
    # For configs we must not touch: hand-written, or one of ours that has been
    # edited. Whoever wrote a config by hand can read Python, so lines are the
    # right level of detail here (FR-1163).
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string[]]$Missing
    )
    Write-Host "[INFO]  This project uses its own strictdoc_config.py, so it is left untouched."
    Write-Host "        To enable the screens this launcher expects, add these to project_features:"
    foreach ($feature in $Missing) {
        Write-Host ('            "{0}",' -f $feature)
    }
    Write-Host "        File: $ConfigPath"
}

function Invoke-ScaffoldUpgradePrompt {
    # FR-1163: the file is ours and untouched, and it is out of date. Explain the
    # outcome in plain language, keep the literal diff one line away for the few
    # who want it, and default to yes -- declining by default would leave most
    # users on the old settings forever, which is the problem this solves.
    param(
        [Parameter(Mandatory)] [string]$ProjectConfigPath,
        [Parameter(Mandatory)] [string]$ServerConfigPath,
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$CurrentText,
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$NewText
    )

    $before = Get-ProjectFeatureList -Text $CurrentText
    $after  = Get-ProjectFeatureList -Text $NewText
    $added   = @($after  | Where-Object { $before -notcontains $_ })
    $removed = @($before | Where-Object { $after  -notcontains $_ })
    $iconsBefore = Get-ToolbarIconCount -Features $before
    $iconsAfter  = Get-ToolbarIconCount -Features $after
    $titleBefore = Get-ProjectTitleFromText -Text $CurrentText
    $titleAfter  = Get-ProjectTitleFromText -Text $NewText

    $proposedDir = Join-Path $env:TEMP 'StrictDocStarter'
    $proposedPath = Join-Path $proposedDir 'strictdoc_config.py.proposed'
    try {
        if (-not (Test-Path -LiteralPath $proposedDir)) {
            $null = New-Item -ItemType Directory -Path $proposedDir -Force -ErrorAction Stop
        }
        Write-FileUtf8NoBom -Path $proposedPath -Content $NewText
    } catch {
        $proposedPath = $null
    }

    Write-Host ""
    Write-Host "[INFO]  This project's settings file was created by an older version of"
    Write-Host "        StrictDocStarter. It can be updated to match the version you are"
    Write-Host "        running now."
    Write-Host ""
    Write-Host ("        What changes:  {0} settings enabled  ->  {1} settings enabled" -f $before.Count, $after.Count)
    Write-Host ("                       {0} icons in the left toolbar  ->  {1} icons" -f $iconsBefore, $iconsAfter)
    if ($titleBefore -ne $titleAfter) {
        Write-Host ("                       project title '{0}'  ->  '{1}'" -f $titleBefore, $titleAfter)
    }
    Write-Host ""
    if ($added.Count -gt 0) {
        Write-Host "        Turned on:"
        foreach ($feature in $added) {
            $label = $script:FeatureDisplayNames[$feature]
            if (-not $label) { $label = $feature }
            Write-Host ("          + {0}" -f $label)
        }
    }
    if ($removed.Count -gt 0) {
        Write-Host "        Removed:"
        foreach ($feature in $removed) {
            $label = $script:FeatureDisplayNames[$feature]
            if (-not $label) { $label = $feature }
            Write-Host ("          - {0}" -f $label)
        }
    }
    if ($script:ScaffoldChangeNotes.Count -gt 0) {
        Write-Host "        Also:"
        foreach ($note in $script:ScaffoldChangeNotes) {
            Write-Host ("          * {0}" -f $note)
        }
    }
    Write-Host ""
    Write-Host "        Your documents are NOT touched. Only this one settings file changes:"
    Write-Host "          $ProjectConfigPath"
    Write-Host "        A backup is written first, in the same folder."
    if ($proposedPath) {
        Write-Host "        Want to compare first? The exact new file is here:"
        Write-Host "          $proposedPath"
    }
    Write-Host ""

    if (-not [Environment]::UserInteractive) {
        Write-Host "[INFO]  Not an interactive session; leaving the settings file as it is."
        return
    }

    $reply = Read-Host "Update the settings file now? [Y/n]"
    if ($reply -and $reply.Trim() -notmatch '^(y|yes)$') {
        Write-Host "[INFO]  Nothing was changed. You will be asked again when a newer"
        Write-Host "        version of StrictDocStarter is released."
        Save-ConfigUpgradeDecline -ConfigPath $ServerConfigPath -ProjectPath $ProjectPath
        return
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$ProjectConfigPath.bak-$stamp"
    try {
        Copy-Item -LiteralPath $ProjectConfigPath -Destination $backupPath -ErrorAction Stop
        Write-FileUtf8NoBom -Path $ProjectConfigPath -Content $NewText
        Write-Host "[INFO]  Updated. Backup saved as $(Split-Path -Leaf $backupPath)."
    } catch {
        Write-Host "[WARN]  Could not update the settings file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Show-GitignoreAdvice {
    # FR-1161: tell the user how to keep the generated output out of Git, but never
    # touch .gitignore. Detection is delegated to git so that nested .gitignore
    # files, "!" negations, .git/info/exclude and core.excludesFile all behave the
    # way git itself behaves. If anything is unclear, say nothing: a wrong hint is
    # worse than no hint. git is already a required tool (lib\auto.ps1 phase B).
    param([Parameter(Mandatory)] [string]$ProjectPath)

    $target = Join-Path $ProjectPath 'output\strictdoc'
    # Ask about the path WITH a trailing slash. On the first launch the folder does
    # not exist yet, and without the slash git treats the path as a file, so a
    # directory-only pattern such as "/docs/spec/output/strictdoc/" does not match
    # and we would nag a user who had already done the right thing. With the slash
    # git treats it as a directory and every pattern style matches (measured).
    $query = ($target -replace '\\', '/') + '/'
    try {
        $root = & git -C $ProjectPath rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($root)) { return }
        $root = $root.Trim() -replace '/', '\'

        & git -C $ProjectPath check-ignore -q -- $query 2>$null
        if ($LASTEXITCODE -ne 1) { return }   # 0 = already ignored, other = cannot tell
    } catch {
        return
    }

    $full = [System.IO.Path]::GetFullPath($target)
    if ($full.Length -le $root.Length) { return }
    $relative = '/' + (($full.Substring($root.Length).TrimStart('\')) -replace '\\', '/') + '/'

    Write-Host ""
    Write-Host "[WARN]  Generated HTML will be written to a folder Git is not ignoring:" -ForegroundColor Yellow
    Write-Host "          $full"
    Write-Host "        Add this one line to $root\.gitignore yourself:"
    Write-Host "          $relative" -ForegroundColor Yellow
    Write-Host "        (This launcher does not edit .gitignore.)"
    Write-Host ""
}

function Initialize-StrictDocProjectConfig {
    # FR-1142..1145 and FR-1163. Three outcomes:
    #   no config          -> scaffold it
    #   our config, stale  -> offer an update (backup first), see FR-1163
    #   anything else      -> never write; print what to add instead
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [string]$ServerConfigPath = ''
    )
    $cfgPy   = Join-Path $ProjectPath 'strictdoc_config.py'
    $cfgToml = Join-Path $ProjectPath 'strictdoc.toml'

    if (Test-Path -LiteralPath $cfgToml) {                                                # FR-1145
        Write-Host "[WARN]  Found strictdoc.toml in the project; not scaffolding strictdoc_config.py. On strictdoc 0.27+ diagrams and math need no toggle there." -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path -LiteralPath $cfgPy)) {
        # Nothing to consent to: the file does not exist yet, so nobody's work is
        # at stake. FR-1167 names it after this folder.
        try {
            Write-FileUtf8NoBom -Path $cfgPy -Content (Get-ScaffoldBody -ProjectPath $ProjectPath)
            Write-Host ("[INFO]  Scaffolded strictdoc_config.py in the project folder, titled '{0}' after the folder (diagrams and math are on by default on strictdoc 0.27+)." -f (Get-ProjectTitleFromPath -ProjectPath $ProjectPath))
        } catch {
            Write-Host "[WARN]  Could not scaffold strictdoc_config.py: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        return
    }

    # A config already exists. Decide who owns it before touching anything.
    try {
        $currentText = Read-FileNoBom -Path $cfgPy
    } catch {
        return
    }

    # A title someone chose is theirs to keep, even across a generation update.
    # Only the placeholders generations 1..3 wrote, and strictdoc's own fallback,
    # give way to the folder name (FR-1167).
    $keepTitle = Get-ProjectTitleFromText -Text $currentText
    if ($script:PlaceholderProjectTitles -contains $keepTitle) { $keepTitle = '' }
    $newText = Get-ScaffoldBody -ProjectPath $ProjectPath -Title $keepTitle

    # Compared with the title masked out, so a project renamed from the browser
    # still counts as up to date rather than as an edit we must keep away from.
    if ((Get-ScaffoldIdentityHash -Text $currentText) -eq (Get-ScaffoldIdentityHash -Text $newText)) { return }

    $missing = @(Get-ProjectFeatureList -Text $newText | Where-Object {
        (Get-ProjectFeatureList -Text $currentText) -notcontains $_
    })

    if (-not (Test-ScaffoldBodyIsOurs -Text $currentText)) {
        # Hand-written, or one of ours that has since been edited (FR-1142).
        if ($missing.Count -gt 0) {
            Show-ProjectConfigSuggestion -ConfigPath $cfgPy -Missing $missing
        }
        # FR-1168: still offer to name the project, since a file with no
        # project_title at all is titled 'Untitled Project' by strictdoc and
        # cannot be renamed from the browser either.
        Invoke-ProjectTitlePrompt -ProjectConfigPath $cfgPy -ProjectPath $ProjectPath -CurrentText $currentText
        return
    }

    if ([string]::IsNullOrWhiteSpace($ServerConfigPath) -or -not (Test-Path -LiteralPath $ServerConfigPath)) {
        return
    }
    if (Test-ConfigUpgradeDeclined -ConfigPath $ServerConfigPath -ProjectPath $ProjectPath) { return }

    Invoke-ScaffoldUpgradePrompt -ProjectConfigPath $cfgPy -ServerConfigPath $ServerConfigPath `
        -ProjectPath $ProjectPath -CurrentText $currentText -NewText $newText
}
