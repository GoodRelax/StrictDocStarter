# StrictDocStarter - change-color-mode.ps1
# Sets "color_mode" (auto / light / dark) in server.config.json (FR-1162).
# Run by change-color-mode.bat. Standalone PowerShell entry point.
# Output language: English ASCII only.

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath   = Join-Path $ScriptDir 'server.config.json'
$TemplatePath = Join-Path $ScriptDir 'server.config.template.json'

. (Join-Path $ScriptDir 'lib\server-config.ps1')

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    if (Test-Path -LiteralPath $TemplatePath) {
        try {
            Initialize-ServerConfig -TemplatePath $TemplatePath -ConfigPath $ConfigPath -StarterRoot $ScriptDir
            Write-Host "[INFO]  Created server.config.json from template."
        } catch {
            Write-Host "[ERROR] Could not create server.config.json: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[ERROR] server.config.json not found, and no template to create it from." -ForegroundColor Red
        Write-Host "        Expected: $ConfigPath"
        exit 1
    }
}

$current = Get-ColorMode -ConfigPath $ConfigPath

Write-Host ""
Write-Host "============================================================"
Write-Host " StrictDocStarter - colour mode"
Write-Host "============================================================"
Write-Host ""
Write-Host "  Current setting: $current"
Write-Host ""
Write-Host "  1. auto    Follow the light/dark setting of Windows  (recommended)"
Write-Host "  2. light   Always light. This is StrictDoc's own appearance."
Write-Host "  3. dark    Always dark."
Write-Host ""
Write-Host "  About dark mode:"
Write-Host "    StrictDoc has no dark mode of its own, so this works by adding a"
Write-Host "    stylesheet on top of it. The text you read goes dark, but a few small"
Write-Host "    controls and the colours inside Mermaid diagrams are only partly"
Write-Host "    covered, and source code highlighting stays as it is."
Write-Host "    Background: https://strictdoc.readthedocs.io/  (see 'Path to custom CSS')"
Write-Host ""
Write-Host "  A project picks up the new setting the next time you open it with"
Write-Host "  launch-strictdoc.bat. Servers that are already running keep the old one."
Write-Host ""

if (-not [Environment]::UserInteractive) {
    Write-Host "[INFO]  Not an interactive session; nothing was changed."
    exit 0
}

$reply = Read-Host "Choose 1-3 (or press Enter to keep '$current')"
$reply = if ($null -eq $reply) { '' } else { $reply.Trim() }

if ($reply -eq '') {
    Write-Host "[INFO]  Kept '$current'. Nothing was changed."
    exit 0
}

$chosen = switch ($reply) {
    '1'     { 'auto' }
    '2'     { 'light' }
    '3'     { 'dark' }
    'auto'  { 'auto' }
    'light' { 'light' }
    'dark'  { 'dark' }
    default { $null }
}

if ($null -eq $chosen) {
    Write-Host "[WARN]  '$reply' is not one of 1, 2 or 3. Nothing was changed." -ForegroundColor Yellow
    exit 1
}

if ($chosen -eq $current) {
    Write-Host "[INFO]  Already set to '$chosen'. Nothing was changed."
    exit 0
}

if (Save-ColorMode -ConfigPath $ConfigPath -Mode $chosen) {
    Write-Host "[INFO]  Colour mode is now '$chosen'."
    Write-Host "        Open a project with launch-strictdoc.bat to see it."
    exit 0
}

exit 1
