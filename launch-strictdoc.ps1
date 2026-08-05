# launch-strictdoc.ps1 - StrictDoc launcher (v1.2, ADR-115 option C: pure launcher, no menu).
# Flow: resolve project_path (D&D / prompt) -> dedup -> free port -> visible
#       "strictdoc server CLI window" -> browser -> save last-used -> exit.
# Spec: docs/serve-spec.md FR-1101..1105, FR-1121, FR-1132..1134, FR-1150..1159, FR-1156b, FR-1157c.
# Output language: English ASCII only (NFR-005 / ADR-008).

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$DroppedPaths = @()
)

$ErrorActionPreference = 'Stop'

# strictdoc writes UTF-8. Without this, PowerShell decodes its output using the
# console code page (cp932 on a Japanese Windows), and any non-ASCII document
# title comes back as mojibake -- which is exactly what the diagnostic dump after
# a failed start used to show. Match gather-logs.ps1, which already does this.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}

# ---- locate self + libraries ----
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$StarterRoot   = $ScriptDir
$ConfigPath    = Join-Path $ScriptDir 'server.config.json'
$TemplatePath  = Join-Path $ScriptDir 'server.config.template.json'
$SampleDefault = Join-Path $ScriptDir 'samples\sovd-automotive-ja'
$libConfig     = Join-Path $ScriptDir 'lib\server-config.ps1'
$libProcess    = Join-Path $ScriptDir 'lib\server-process.ps1'

function Complete-AndExit {
    # On error we pause so the user can read the message; on success we just close
    # (the persistent UI is the strictdoc server CLI window). Skip the pause when
    # stdin is redirected (automated/piped runs) so they never hang.
    param([int]$Code = 0, [bool]$Pause = $false)
    if ($Pause -and -not [Console]::IsInputRedirected) {
        Write-Host ""
        $null = Read-Host "Press Enter to close"
    }
    exit $Code
}

# FR-1134: verify libraries are present (OneDrive Files On-Demand placeholder guard).
foreach ($lib in @($libConfig, $libProcess)) {
    if (-not (Test-Path $lib)) {
        Write-Host "[ERROR] Missing library: $lib" -ForegroundColor Red
        Write-Host "        If on OneDrive, right-click the StrictDocStarter folder -> 'Always keep on this device'." -ForegroundColor Yellow
        Complete-AndExit -Code 1 -Pause $true
    }
}
. $libConfig
. $libProcess

# ---- FR-1132: warn on synced / space / non-ASCII install path ----
$riskyPath = $false
$od = "$env:OneDrive"
if (-not [string]::IsNullOrEmpty($od)) {
    $odPrefix = ($od.TrimEnd('\') + '\').ToLowerInvariant()
    if ($ScriptDir.ToLowerInvariant().StartsWith($odPrefix)) { $riskyPath = $true }
}
if ($ScriptDir -match '\s') { $riskyPath = $true }
foreach ($ch in $ScriptDir.ToCharArray()) { if ([int][char]$ch -gt 127) { $riskyPath = $true; break } }
if ($riskyPath) {
    Write-Host "[WARN]  Running from a synced/space/non-ASCII path. A local path like C:\StrictDocStarter is recommended." -ForegroundColor Yellow
}

# ---- FR-1105: strictdoc must be installed ----
$strictdocExe = Resolve-StrictDocExecutable
if ($null -eq $strictdocExe) {
    Write-Host "[ERROR] strictdoc not found. Run setup-strictdoc.bat first." -ForegroundColor Red
    Complete-AndExit -Code 1 -Pause $true
}

# ---- first-run config scaffold (FR-1142) ----
if (-not (Test-Path $ConfigPath)) {
    if (Test-Path $TemplatePath) {
        try {
            Initialize-ServerConfig -TemplatePath $TemplatePath -ConfigPath $ConfigPath -StarterRoot $StarterRoot
            Write-Host "[INFO]  Created server.config.json from template."
        } catch {
            Write-Host "[WARN]  Could not create server.config.json: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# ---- load config (project_path optional; host/port validated) ----
$bindHost          = '127.0.0.1'
$startPort         = 5111
$openBrowser       = $true
$outputPath        = ''
$configProjectPath = ''
if (Test-Path $ConfigPath) {
    $cfgResult = Get-ServerConfig -Path $ConfigPath -StarterRoot $StarterRoot
    if ($null -ne $cfgResult.Config) {
        if (-not [string]::IsNullOrWhiteSpace($cfgResult.Config.host)) { $bindHost = $cfgResult.Config.host }
        if ([int]$cfgResult.Config.port -ge 1025)                     { $startPort = [int]$cfgResult.Config.port }
        $openBrowser       = [bool]$cfgResult.Config.open_browser
        $outputPath        = "$($cfgResult.Config.output_path)"
        $configProjectPath = "$($cfgResult.Config.project_path)"
    }
    if (-not $cfgResult.Validation.Ok) {
        Write-Host "[WARN]  Config issue ($($cfgResult.Validation.ErrorField)): $($cfgResult.Validation.ErrorMessage). Using defaults where needed." -ForegroundColor Yellow
    }
}

# ---- resolve project_path (FR-1150 / 1151 / 1152 / 1153 / 1154) ----
# Prompt default (FR-1153b): config.project_path if it is a real folder, else the bundled sample.
$defaultPath = $configProjectPath
if ([string]::IsNullOrWhiteSpace($defaultPath) -or -not (Test-Path -LiteralPath $defaultPath -PathType Container)) {
    if (Test-Path -LiteralPath $SampleDefault -PathType Container) { $defaultPath = $SampleDefault } else { $defaultPath = '' }
}
$projectPath = Resolve-ProjectPathFromInput -DroppedPaths $DroppedPaths -DefaultPath $defaultPath
if ($null -eq $projectPath) {
    Complete-AndExit -Code 0 -Pause $false   # cancelled (FR-1153c)
}
Write-Host "[INFO]  Project: $projectPath"

# ---- FR-1158: dedup -- is this folder already being served? ----
$existingPort = Find-ServerPortForPath -ProjectPath $projectPath
if ($existingPort -gt 0) {
    Write-Host "[INFO]  Already serving this folder on port $existingPort. Opening browser..."
    if ($openBrowser) { Open-BrowserAt -BindHost $bindHost -Port $existingPort }
    Complete-AndExit -Code 0 -Pause $false
}

# ---- FR-1142..1145 / FR-1163: ensure the project has a strictdoc_config.py, and offer to
# ---- refresh one this launcher wrote itself when an older generation is found ----
Initialize-StrictDocProjectConfig -ProjectPath $projectPath -ServerConfigPath $ConfigPath

# ---- FR-1162: keep the project's stylesheet in step with color_mode. Must run after
# ---- the config step above, which is what puts custom_css_path in the project ----
Update-ProjectTheme -ProjectPath $projectPath -StarterRoot $ScriptDir -Mode (Get-ColorMode -ConfigPath $ConfigPath)

# ---- FR-1164: drop generated pages whose source document has been deleted. The cache
# ---- is left alone; only .html with no corresponding .sdoc/.md goes ----
$effectiveOutput = if ([string]::IsNullOrWhiteSpace($outputPath)) { Join-Path $projectPath 'output\strictdoc' } else { $outputPath }
Remove-OrphanedOutput -ProjectPath $projectPath -OutputPath $effectiveOutput

# ---- FR-1161: say how to keep the generated output out of Git; never edit .gitignore ----
Show-GitignoreAdvice -ProjectPath $projectPath

# ---- FR-1156 / FR-1156b: pick a free port from the start port ----
$ceiling   = Get-PortCeiling -Start $startPort
$candidate = Get-FreePort   -Start $startPort
if ($candidate -le 0) {
    Write-Host "[ERROR] No free port in range $startPort..$ceiling." -ForegroundColor Red   # FR-1156b
    Complete-AndExit -Code 1 -Pause $true
}

# ---- launch + adoption re-probe (FR-1101 / FR-1157), retry on TOCTOU race ----
$maxRetries    = 5
$attempt       = 0
$adoptedPort   = 0
$startupFailed = $false
while ($attempt -lt $maxRetries) {
    $attempt++
    Write-Host "[INFO]  Starting strictdoc server on port $candidate (attempt $attempt)..."
    if (-not (Start-StrictDocCliWindow -StrictDocExe $strictdocExe -ProjectPath $projectPath -BindHost $bindHost -Port $candidate -OutputPath $outputPath)) {
        Complete-AndExit -Code 1 -Pause $true
    }

    $adopt = Confirm-PortAdoption -Port $candidate
    $r = $adopt.Result
    if ($r -eq 'adopted' -or $r -eq 'timeout') {
        if ($r -eq 'timeout') {
            Write-Host "[WARN]  Server still starting on port $candidate; opening the browser anyway (it will load when ready)." -ForegroundColor Yellow
        }
        $adoptedPort = $candidate
        break
    } elseif ($r -eq 'failed') {
        $startupFailed = $true
        break
    } else {
        # 'race' (FR-1157b): another process grabbed the port between scan and bind.
        Write-Host "[WARN]  Port $candidate was taken by another process; trying the next free port." -ForegroundColor Yellow
        $next = Get-FreePort -Start ($candidate + 1)
        if ($next -le 0 -or $next -gt $ceiling) {
            Write-Host "[ERROR] Could not bind a free port near $startPort (tried $attempt)." -ForegroundColor Red
            Complete-AndExit -Code 1 -Pause $true
        }
        $candidate = $next
    }
}

# ---- FR-1157c: startup failure (e.g. .sdoc parse error) -- surface the cause, no browser ----
if ($startupFailed) {
    Show-StartupErrorDiagnostic -StrictDocExe $strictdocExe -ProjectPath $projectPath -Port $candidate
    Complete-AndExit -Code 1 -Pause $true
}
if ($adoptedPort -le 0) {
    Write-Host "[ERROR] Could not bind a free port near $startPort after $attempt attempts." -ForegroundColor Red
    Complete-AndExit -Code 1 -Pause $true
}

# ---- success: open browser (FR-1159) + save last-used (FR-1155) ----
Write-Host "[OK]    StrictDoc server running on port $adoptedPort." -ForegroundColor Green
if ($openBrowser) { Open-BrowserAt -BindHost $bindHost -Port $adoptedPort }
Save-LastUsedProjectPath -ConfigPath $ConfigPath -ProjectPath $projectPath
Write-Host "[INFO]  The server runs in its own window titled 'StrictDoc Web Server (...)'. Close that window (or Ctrl+C) to stop it."
Complete-AndExit -Code 0 -Pause $false
