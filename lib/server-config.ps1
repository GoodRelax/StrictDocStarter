# lib/server-config.ps1 - server.config.json gen / load / validate / editor launch.
# Functions: Initialize-ServerConfig, Get-ServerConfig, Open-EditorForConfig,
#            Expand-UserPlaceholdersInString.
# Spec: FR-201..213 (config management), FR-208 (Expand-UserPlaceholders).
# Output language: English ASCII only (per NFR-005 / ADR-008).
#
# NOTE: dot-sourced from manage-strictdoc.ps1 (not a module). Functions are
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
    #   <starter_root>  -> absolute path of manage-strictdoc.bat's folder
    # The second placeholder lets server.config.template.json point at the
    # bundled samples (samples/hello-strictdoc) regardless of where the
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

        # FR-1154b: warn (non-fatal) if no .sdoc files.
        $sdoc = @(Get-ChildItem -LiteralPath $resolved -Filter *.sdoc -File -ErrorAction SilentlyContinue)
        if ($sdoc.Count -eq 0) {
            Write-Host "[WARN]  No .sdoc files found under $resolved. Starting as an empty project." -ForegroundColor Yellow
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

function Initialize-StrictDocProjectConfig {
    # FR-1142..1145: ensure <ProjectPath>\strictdoc_config.py exists so MERMAID / MATHJAX
    # render. An existing strictdoc_config.py is left untouched (FR-1142). If a legacy
    # strictdoc.toml exists, skip with a WARN (FR-1145). Write failure is non-fatal (FR-1144).
    # Shape follows official `strictdoc new` (create_config -> ProjectConfig) plus MERMAID/MATHJAX.
    param([Parameter(Mandatory)] [string]$ProjectPath)
    $cfgPy   = Join-Path $ProjectPath 'strictdoc_config.py'
    $cfgToml = Join-Path $ProjectPath 'strictdoc.toml'
    if (Test-Path -LiteralPath $cfgPy) { return }                                         # FR-1142
    if (Test-Path -LiteralPath $cfgToml) {                                                # FR-1145
        Write-Host "[WARN]  Found strictdoc.toml in the project; not scaffolding strictdoc_config.py. Enable MERMAID/MATHJAX there if you need diagrams/math." -ForegroundColor Yellow
        return
    }
    $content = @'
# StrictDoc project configuration scaffolded by StrictDocStarter (manage-strictdoc).
#
# Placed in this project folder so `strictdoc server <this folder>` enables the features
# below. StrictDoc reads the config from the input folder itself, not parent folders
# (verified on strictdoc 0.23.1). Shape follows the official `strictdoc new` output
# (create_config() returning a ProjectConfig) plus MERMAID + MATHJAX, which `strictdoc new`
# leaves off. Edit freely -- StrictDocStarter never overwrites an existing strictdoc_config.py.
#
# Docs: https://strictdoc.readthedocs.io/
from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        project_title="StrictDoc Project",
        project_features=[
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "DEEP_TRACEABILITY_SCREEN",
            "SEARCH",
            "MATHJAX",
            "MERMAID",
        ],
    )
'@
    try {
        Write-FileUtf8NoBom -Path $cfgPy -Content $content
        Write-Host "[INFO]  Scaffolded strictdoc_config.py (MERMAID + MATHJAX) in the project folder."
    } catch {
        Write-Host "[WARN]  Could not scaffold strictdoc_config.py: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
