# StrictDocStarter - lib/install.ps1
# Tool installation (winget / pip / VS Code extensions).
# STATUS: all phases implemented (FR-360). Phase A = VS Code + Claude Code
# extension, B = Git/Python/gh via winget, C = StrictDoc via pip, D = clone
# (lib/clone.ps1), E = optional tools + VS Code extensions.
# Spec refs: FR-301 to FR-310, FR-330 to FR-339, FR-805

# Extension ID for the Claude Code VS Code extension.
# Update if Anthropic publishes under a different ID.
$script:CCExtensionId = "anthropic.claude-code"

# Required tool winget IDs (FR-301).
# Python ID is built dynamically from config (e.g. Python.Python.3.13).
$script:RequiredTools = @(
    @{ Key = "git";    Id = "Git.Git";     Display = "Git";        Cmd = "git" }
    @{ Key = "gh";     Id = "GitHub.cli";  Display = "GitHub CLI"; Cmd = "gh" }
    # python is handled specially because the ID embeds the version
)

# Optional tools (FR-302). Mapping: config option key -> winget id, display name,
# command (for PATH-based detection), and DisplayName pattern (for registry-based
# detection when no command is available on PATH, e.g. Obsidian).
# VS Code is handled by Phase A (required for Claude Code extension); it is
# intentionally not in the Optional tools list to avoid duplicate plan rows.
$script:OptionalTools = @(
    @{ OptKey = "install_obsidian"; Id = "Obsidian.Obsidian";          Display = "Obsidian";         Cmd = $null;  RegistryName = "Obsidian" }
    @{ OptKey = "install_terminal"; Id = "Microsoft.WindowsTerminal";  Display = "Windows Terminal"; Cmd = "wt";   RegistryName = $null }
    @{ OptKey = "install_pwsh7";    Id = "Microsoft.PowerShell";       Display = "PowerShell 7";     Cmd = "pwsh"; RegistryName = $null }
    @{ OptKey = "install_ripgrep";  Id = "BurntSushi.ripgrep.MSVC";    Display = "ripgrep";          Cmd = "rg";   RegistryName = $null }
    @{ OptKey = "install_jq";       Id = "jqlang.jq";                  Display = "jq";               Cmd = "jq";   RegistryName = $null }
)

# ---------------------------------------------------------------------------
# Detection helpers
# ---------------------------------------------------------------------------

function Update-PathFromRegistry {
    # Refresh $env:Path from Machine + User registry. Equivalent to opening a new shell.
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($machine -and $user) {
        $env:Path = "$machine;$user"
    } elseif ($machine) {
        $env:Path = $machine
    }
}

function Get-VSCodeCommand {
    # Returns path to 'code.cmd' (or 'code' on PATH). 3-stage detection:
    #   1. PATH (Get-Command)
    #   2. Known install locations (user-scope and machine-scope defaults)
    #   3. Registry Uninstall key -> InstallLocation or DisplayIcon
    # Step 3 catches non-standard install paths (corporate IT deployments,
    # custom dirs, drive D:, etc.) as long as VS Code registered itself.

    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        "$env:LocalAppData\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }

    # Registry fallback (function defined later in this file; safe to call
    # because PS resolves function references at invocation time)
    $reg = Get-InstalledAppFromRegistry "Microsoft Visual Studio Code"
    if ($reg) {
        $first = @($reg)[0]
        if ($first.InstallLocation) {
            $c = Join-Path $first.InstallLocation "bin\code.cmd"
            if (Test-Path $c) { return $c }
        }
        if ($first.DisplayIcon) {
            # DisplayIcon is typically "C:\path\Code.exe,0"
            $iconPath = ($first.DisplayIcon -split ',')[0].Trim('"')
            if ($iconPath -and (Test-Path $iconPath)) {
                $codeDir  = Split-Path $iconPath -Parent
                $c = Join-Path $codeDir "bin\code.cmd"
                if (Test-Path $c) { return $c }
            }
        }
    }

    return $null
}

function Test-VSCodeInstalled {
    return [bool](Get-VSCodeCommand)
}

function Test-ClaudeCodeExtensionInstalled {
    $code = Get-VSCodeCommand
    if (-not $code) { return $false }
    try {
        $exts = & $code --list-extensions 2>$null
        if (-not $exts) { return $false }
        # Match anthropic.claude-code (case-insensitive) and any close variant
        return [bool]($exts | Where-Object { $_ -match '(?i)anthropic\.claude' })
    } catch {
        return $false
    }
}

function Get-ClaudeCodeStatus {
    # Aggregated status used by 'auto' planner.
    $vscode  = Test-VSCodeInstalled
    $cc_ext  = $false
    $cc_cli  = [bool](Get-Command claude -ErrorAction SilentlyContinue)
    if ($vscode) { $cc_ext = Test-ClaudeCodeExtensionInstalled }
    return [pscustomobject]@{
        VSCodeInstalled         = $vscode
        CCExtensionInstalled    = $cc_ext
        CCCLIInstalled          = $cc_cli
    }
}

function Test-PythonStoreStub {
    # The Microsoft Store python.exe stub lives under WindowsApps and either
    # opens the Store or prints "Python " with no version. Treat it as not
    # installed so Phase B will actually install a real Python via winget.
    param([string]$Path)
    if (-not $Path) { return $false }
    if ($Path -match '\\WindowsApps\\') { return $true }
    return $false
}

function Get-PythonCommand {
    # Returns a path to a REAL python.exe (or py.exe) - excludes the Microsoft
    # Store stub. Returns $null if only the stub is present.
    foreach ($name in @("python", "py")) {
        $c = Get-Command $name -ErrorAction SilentlyContinue
        if (-not $c) { continue }
        if (Test-PythonStoreStub $c.Source) { continue }
        # Sanity check: --version must print "Python X.Y.Z".
        # Capture all output, then match. Piping to `Select -First 1`
        # would TerminateProcess the upstream exe (PS pipeline pitfall);
        # though Python is usually fast enough to escape, this hardens
        # detection on slow systems / containers.
        try {
            $all = & $c.Source --version 2>&1
            $out = $all | Where-Object { $_ } | Select-Object -First 1
            if ($out -match 'Python\s+\d+\.\d+') { return $c.Source }
        } catch {}
    }
    return $null
}

function Test-PythonInstalled {
    return [bool](Get-PythonCommand)
}

function Get-RequiredToolsStatus {
    # Returns hashtable: ToolKey -> @{ Installed=bool; Version=string }
    $result = [ordered]@{}
    foreach ($t in $script:RequiredTools) {
        $cmd = Get-Command $t.Cmd -ErrorAction SilentlyContinue
        if ($cmd) {
            $ver = ""
            try {
                $all = & $t.Cmd --version 2>$null
                $ver = $all | Where-Object { $_ } | Select-Object -First 1
            } catch {}
            $result[$t.Key] = @{ Installed = $true; Version = [string]$ver }
        } else {
            $result[$t.Key] = @{ Installed = $false; Version = "" }
        }
    }
    $py = Get-PythonCommand
    if ($py) {
        $pyver = ""
        try { $pyver = (& $py --version 2>$null) } catch {}
        $result["python"] = @{ Installed = $true; Version = [string]$pyver }
    } else {
        $result["python"] = @{ Installed = $false; Version = "" }
    }
    return $result
}

# ---------------------------------------------------------------------------
# Installers
# ---------------------------------------------------------------------------

function Confirm-InstallResult {
    # FR-312 / ADR-013: two-stage verification combining the installer's exit
    # code with a post-install state probe (Test-*Installed / Get-Command).
    # Returns $true if the tool is present, even when the installer's exit
    # code disagrees -- log a [VERIFIED] notice in that case so the override
    # is auditable in setup.log.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [bool]$ExitOk,
        [Parameter(Mandatory)] [bool]$StateOk,
        [Parameter(Mandatory)] [string]$Label,
        [string]$Version = $null
    )
    if ($ExitOk -and $StateOk) {
        return $true
    }
    if (-not $ExitOk -and $StateOk) {
        $msg = "[VERIFIED] $Label is present despite installer non-zero exit"
        if ($Version) { $msg = "$msg (version: $Version)" }
        Write-OnboardWarn $msg
        return $true
    }
    if ($ExitOk -and -not $StateOk) {
        Write-OnboardWarn "$Label installer exit=0 but tool not detected (may need shell restart)"
        return $false
    }
    Write-OnboardWarn "$Label install failed (installer non-zero exit, tool not detected)"
    return $false
}

function Invoke-WingetInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Id,
        [string]$DisplayName = $null
    )
    if (-not $DisplayName) { $DisplayName = $Id }

    Write-OnboardInfo "winget install $DisplayName ($Id)"
    $args = @(
        "install",
        "--id", $Id,
        "-e",
        "--accept-source-agreements",
        "--accept-package-agreements",
        "--silent"
    )
    try {
        $proc = Start-Process -FilePath "winget" -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            Write-OnboardOk "$DisplayName installed"
            Update-PathFromRegistry
            return $true
        } elseif ($proc.ExitCode -eq -1978335189) {
            # APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
            Write-OnboardSkip "$DisplayName already installed"
            return $true
        } else {
            Write-OnboardError "winget install $DisplayName failed (exit $($proc.ExitCode))"
            return $false
        }
    } catch {
        Write-OnboardError "winget install $DisplayName threw: $($_.Exception.Message)"
        return $false
    }
}

function Install-VSCodeIfNeeded {
    if (Test-VSCodeInstalled) {
        Write-OnboardSkip "VS Code already installed: $(Get-VSCodeCommand)"
        return $true
    }
    $ok = Invoke-WingetInstall -Id "Microsoft.VisualStudioCode" -DisplayName "VS Code"
    Update-PathFromRegistry
    # FR-312 two-stage: even if winget reports failure, the file may be in
    # place (rare but observed for VS Code under noisy network conditions).
    return Confirm-InstallResult -ExitOk $ok -StateOk (Test-VSCodeInstalled) -Label "VS Code"
}

function Get-InstalledAppFromRegistry {
    # Queries the Windows Uninstall registry keys for an app whose DisplayName
    # contains the given substring (case-insensitive). Returns matching items
    # or $null. Used to detect GUI apps without a CLI command on PATH.
    # Fast: pure registry read, no external commands.
    param([Parameter(Mandatory)] [string]$DisplayNameSubstring)

    $keys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($k in $keys) {
        try {
            $items = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
                     Where-Object { $_.DisplayName -and ($_.DisplayName -like "*$DisplayNameSubstring*") }
            if ($items) { return $items }
        } catch {}
    }
    return $null
}

function Test-OptionalToolInstalled {
    param([hashtable]$Tool)
    # 1. Command on PATH (fastest)
    if ($Tool.Cmd) {
        if (Get-Command $Tool.Cmd -ErrorAction SilentlyContinue) { return $true }
    }
    # 2. Registry Uninstall key (robust for GUI apps)
    if ($Tool.RegistryName) {
        if (Get-InstalledAppFromRegistry $Tool.RegistryName) { return $true }
    }
    # 3. Known install-path fallback for specific apps where registry lookup
    #    may not catch all installer variants
    if ($Tool.Id -eq "Obsidian.Obsidian") {
        $paths = @(
            "$env:LOCALAPPDATA\Obsidian\Obsidian.exe",
            "$env:LOCALAPPDATA\Programs\obsidian\Obsidian.exe",
            "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe",
            "$env:ProgramFiles\Obsidian\Obsidian.exe"
        )
        foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    }
    return $false
}

function Get-VSCodeInstalledExtensions {
    $code = Get-VSCodeCommand
    if (-not $code) { return @() }
    try {
        $list = & $code --list-extensions 2>$null
        return @($list)
    } catch {
        return @()
    }
}

function Install-OptionalTools {
    [CmdletBinding()]
    param($Config)
    $results = [ordered]@{}
    foreach ($t in $script:OptionalTools) {
        $optKey = $t.OptKey
        $enabled = $false
        if ($Config -and $Config.options -and $Config.options.PSObject.Properties.Name -contains $optKey) {
            $enabled = [bool]$Config.options.$optKey
        }
        if (-not $enabled) {
            Write-OnboardSkip "$($t.Display) disabled in config"
            $results[$optKey] = $true   # not a failure, just disabled
            continue
        }
        if (Test-OptionalToolInstalled $t) {
            Write-OnboardSkip "$($t.Display) already installed"
            $results[$optKey] = $true
            continue
        }
        $ok = Invoke-WingetInstall -Id $t.Id -DisplayName $t.Display
        Update-PathFromRegistry
        # FR-312 two-stage: trust the post-install detection over winget's
        # exit code so transient stderr / exit-code quirks don't cause false
        # failures when the tool is actually in place.
        $results[$optKey] = Confirm-InstallResult -ExitOk $ok `
                                                  -StateOk (Test-OptionalToolInstalled $t) `
                                                  -Label $t.Display
    }
    return $results
}

function Install-VSCodeExtensions {
    [CmdletBinding()]
    param($Config)
    if (-not $Config -or -not $Config.vscode -or -not $Config.vscode.extensions) {
        Write-OnboardSkip "No VS Code extensions configured"
        return @{}
    }
    $code = Get-VSCodeCommand
    if (-not $code) {
        Write-OnboardWarn "VS Code not available; skipping extensions"
        return @{}
    }
    $installed = Get-VSCodeInstalledExtensions
    $results = [ordered]@{}
    foreach ($ext in $Config.vscode.extensions) {
        $extId = [string]$ext
        if ($installed -contains $extId) {
            Write-OnboardSkip "Extension $extId already installed"
            $results[$extId] = $true
            continue
        }
        Write-OnboardInfo "code --install-extension $extId"
        # FR-311 / ADR-011: 'code --install-extension' can write informational
        # text to stderr even on success; with global EAP=Stop the 2>&1 merge
        # turns those into terminating errors. Drop EAP locally and trust
        # $LASTEXITCODE only. FR-312 (ADR-013): also verify final state by
        # re-listing extensions and check the requested ID is present.
        $extExit = 1
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            & $code --install-extension $extId --force 2>&1 | ForEach-Object { Write-Host "  $_" }
            $extExit = $LASTEXITCODE
        } catch {
            Write-OnboardWarn "Extension $extId threw (continuing to verify): $($_.Exception.Message)"
        } finally {
            $ErrorActionPreference = $oldEAP
        }
        # FR-312 two-stage verification: trust the post-install ext listing
        # more than the exit code. If exit non-zero but the extension is in
        # the list, log a [VERIFIED] upgrade. If exit zero but missing, warn.
        $postList = Get-VSCodeInstalledExtensions
        $present  = ($postList -contains $extId)
        if ($extExit -eq 0 -and $present) {
            $results[$extId] = $true
        } elseif ($extExit -ne 0 -and $present) {
            Write-OnboardWarn "[VERIFIED] Extension $extId is present despite exit $extExit"
            $results[$extId] = $true
        } elseif ($extExit -eq 0 -and -not $present) {
            Write-OnboardWarn "Extension $extId exit=0 but not present after install"
            $results[$extId] = $false
        } else {
            Write-OnboardWarn "Extension $extId install failed (exit $extExit, not present)"
            $results[$extId] = $false
        }
    }
    return $results
}

# FR-332: the strictdoc version this repository has been verified against.
# Kept in sync with the "Verified StrictDoc version" section of
# docs/04-starter-guide.md (it lived in README.md until that page was split out).
# Used for reporting only -- nothing refuses to run on a different version.
$script:StrictDocVerifiedVersion = "0.27.1"

function Test-StrictDocInstalled {
    return [bool](Get-Command strictdoc -ErrorAction SilentlyContinue)
}

function Get-StrictDocServerProcess {
    # FR-343a: live 'strictdoc' processes, which are what make a pip upgrade fail.
    #
    # launch-strictdoc.bat starts the server by running strictdoc.exe directly
    # (lib/server-process.ps1 FR-1101), so an open server window holds a handle
    # on <python>\Scripts\strictdoc.exe. Windows will not let pip replace a file
    # that is open: pip fails with [WinError 32] -- but only AFTER it has already
    # removed the old package, leaving strictdoc.exe on PATH with no package
    # behind it. Checking first is local and instant, and it is the difference
    # between a clear message and a broken environment.
    #
    # Matching on the process name (not the command line) is deliberate: this
    # must not need WMI/CIM, which setup does not otherwise depend on.
    return @(Get-Process -Name strictdoc -ErrorAction SilentlyContinue)
}

# FR-345a: set when Phase C stopped because something had to be closed first,
# so the summary can say BLOCKED instead of FAILED. Nothing was attempted and
# nothing is broken -- calling that a failure sends people looking for damage
# that is not there.
$script:StrictDocBlockedByRunningProcess = $false

function Confirm-StrictDocNotRunning {
    # FR-343a: $true when it is safe to let pip touch the strictdoc files.
    # Prints what has to be closed when it is not.
    # @(...) at the call site: `return @($x)` unwraps a one-element array back
    # to a scalar, and .Count on a scalar is not dependable across object
    # types. One running server is the common case, so this must not be
    # left to that shim.
    $procs = @(Get-StrictDocServerProcess)
    if ($procs.Count -eq 0) {
        $script:StrictDocBlockedByRunningProcess = $false
        return $true
    }
    $script:StrictDocBlockedByRunningProcess = $true

    Write-OnboardError "$($procs.Count) strictdoc process(es) are running. pip cannot replace a file that is open."
    foreach ($p in $procs) {
        $started = try { $p.StartTime.ToString('yyyy-MM-dd HH:mm:ss') } catch { 'unknown' }
        Write-OnboardInfo ("  PID {0}  started {1}" -f $p.Id, $started)
    }
    Write-OnboardInfo "Close every StrictDoc server window (the ones launch-strictdoc.bat opened), then run this again."
    Write-OnboardInfo "Nothing has been changed."
    return $false
}

function Show-StrictDocLockedRecovery {
    # FR-343a: what to do after pip has already failed on a locked file. The
    # plain "pip install strictdoc==<old>" hint is not enough here -- it fails
    # the same way while the file is still open, and pip leaves a renamed
    # '~trictdoc' folder that makes every later pip call print
    # "Ignoring invalid distribution".
    [CmdletBinding()]
    param([string]$PreviousVersion)

    Write-OnboardError "pip could not replace strictdoc: a file was in use ([WinError 32])."
    Write-OnboardWarn  "The installation may now be half-removed. strictdoc.exe can survive while the"
    Write-OnboardWarn  "  package behind it is gone, so 'strictdoc' then fails with ModuleNotFoundError."
    Write-OnboardInfo  "To recover:"
    Write-OnboardInfo  "  1. Close every StrictDoc server window."
    Write-OnboardInfo  "  2. Delete any leftover '~trictdoc*' folder in site-packages. Find it with:"
    Write-OnboardInfo  '       python -c "import strictdoc, os" 2>NUL || python -m site --user-site'
    Write-OnboardInfo  "     (site-packages is also named in the pip error above.)"
    Write-OnboardInfo  "  3. Re-run setup-strictdoc.bat."
    if ($PreviousVersion) {
        Write-OnboardInfo "  To go back to the version that was installed: pip install `"strictdoc==$PreviousVersion`""
    }
}

function Get-StrictDocVersionSpec {
    # FR-330: read strictdoc.version from setup.config.json.
    # Returns "latest" for missing/blank so callers never handle $null.
    [CmdletBinding()]
    param($Config = $null)

    if (-not $Config) { return "latest" }
    if (-not ($Config.PSObject.Properties.Name -contains "strictdoc")) { return "latest" }
    $sd = $Config.strictdoc
    if (-not $sd) { return "latest" }
    if (-not ($sd.PSObject.Properties.Name -contains "version")) { return "latest" }
    $v = [string]$sd.version
    if ([string]::IsNullOrWhiteSpace($v)) { return "latest" }
    return $v.Trim()
}

function Resolve-StrictDocPipTarget {
    # FR-331: turn a configured version spec into the single argument handed
    # to pip.
    #     "latest"        -> "strictdoc"
    #     "==0.23.1"      -> "strictdoc==0.23.1"
    #     ">=0.23,<0.24"  -> "strictdoc>=0.23,<0.24"
    #     "0.23.1"        -> "strictdoc==0.23.1"   (bare version is common)
    #
    # Returns $null when the spec is not recognised. Callers MUST refuse
    # rather than fall back to "latest": silently installing a different
    # version than the one the user pinned is worse than stopping. The
    # operator sees the offending value and the accepted forms.
    #
    # The alternation lists two-character operators before their one-character
    # prefixes so ">=" is not matched as ">".
    [CmdletBinding()]
    param([string]$Spec)

    if ([string]::IsNullOrWhiteSpace($Spec)) { return "strictdoc" }
    $s = $Spec.Trim()
    if ($s -eq "latest") { return "strictdoc" }
    if ($s -match '^(~=|==|>=|<=|!=|<|>)') { return "strictdoc$s" }
    if ($s -match '^\d')                   { return "strictdoc==$s" }
    return $null
}

function Show-StrictDocSpecError {
    # Shared message for an unusable strictdoc.version value (FR-331).
    [CmdletBinding()]
    param([string]$Spec)
    Write-OnboardError "Invalid strictdoc.version in setup.config.json: '$Spec'"
    Write-OnboardError "Accepted: 'latest', a PEP 440 specifier ('==0.23.1', '~=0.23.0', '>=0.23,<0.24'),"
    Write-OnboardError "          or a bare version ('0.23.1', read as '==0.23.1')."
}

function Get-StrictDocVersion {
    try {
        # Capture-then-pick to avoid the `| Select-Object -First 1`
        # TerminateProcess pitfall (see vm-tests/run-tests.ps1 Test-CmdWorks).
        # strictdoc.exe is a Python launcher whose exit is just slow enough
        # to be caught by Select's StopUpstreamCommandsException.
        $all = & strictdoc --version 2>$null
        $out = $all | Where-Object { $_ } | Select-Object -First 1
        if ($out) { return ([string]$out).Trim() }
    } catch {}
    return $null
}

function Invoke-StrictDocPip {
    # One place that actually calls pip for strictdoc, used by the install
    # path, the reconcile path and 'upgrade'. Returns $true when pip exited 0.
    #
    # FR-311 / ADR-011: pip writes benign text to stderr, so $ErrorActionPreference
    # is relaxed locally and $LASTEXITCODE is what gets trusted. Callers pair
    # this with the FR-312 two-stage check (does strictdoc actually run?).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Python,
        [Parameter(Mandatory)] [string]$Target,
        [switch]$Upgrade
    )
    # --quiet matches how winget is driven here (--silent + our own [INFO]/[OK]
    # lines). Without it every run prints 80+ "Requirement already satisfied"
    # lines, which became noise on EVERY setup once Phase C started calling pip
    # instead of skipping. -q leaves warnings and errors visible, and the
    # outcome is reported by the caller as "<before> -> <after>" anyway.
    $pipArgs = @("-m", "pip", "install", "--quiet")
    if ($Upgrade) { $pipArgs += "--upgrade" }
    $pipArgs += $Target

    Write-OnboardInfo ("pip " + (($pipArgs | Select-Object -Skip 2) -join " ") + " ... (may take a few minutes)")

    # FR-343a: remember whether pip failed on a locked file, so the caller can
    # print the recovery steps instead of the generic "reinstall the old
    # version" hint, which fails the same way while the file is still open.
    # [WinError 32] is the reliable token: the sentence around it is localised
    # by Windows and arrives mojibaked in a non-UTF-8 console.
    $script:StrictDocPipFileLocked = $false

    $exit = 1
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        # 2>&1 on a native command turns each stderr line into an ErrorRecord,
        # and printing one directly yields the useless string
        # "System.Management.Automation.RemoteException" instead of the text.
        # pip writes its "[notice] A new release of pip..." there, so that
        # artifact showed up on every run and read like a failure. Unwrap it.
        & $Python @pipArgs 2>&1 | ForEach-Object {
            $line = if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $_.Exception.Message
            } else {
                [string]$_
            }
            if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Host "  $line" }
            if ($line -match 'WinError 32') { $script:StrictDocPipFileLocked = $true }
        }
        $exit = $LASTEXITCODE
    } catch {
        Write-OnboardWarn "pip threw (continuing to verify): $($_.Exception.Message)"
    } finally {
        $ErrorActionPreference = $oldEAP
    }
    return ($exit -eq 0)
}

function Install-StrictDoc {
    [CmdletBinding()]
    param($Config = $null)

    $python = Get-PythonCommand
    if (-not $python) {
        Write-OnboardError "Python not found on PATH. Cannot install strictdoc."
        return $false
    }

    # FR-330 / FR-331: the configured spec decides what gets installed.
    $spec   = Get-StrictDocVersionSpec -Config $Config
    $target = Resolve-StrictDocPipTarget -Spec $spec
    if (-not $target) {
        Show-StrictDocSpecError -Spec $spec
        return $false
    }

    # FR-335: reconcile an existing installation with strictdoc.version.
    #
    # This phase used to return here untouched, so "version: latest" in the
    # config did not mean latest: a machine without strictdoc got the newest
    # release while a machine that already had it stayed frozen, from the same
    # command. The config was declarative but unenforced.
    #
    # The user's single 'yes' on the plan is the consent for this. The plan row
    # says [INSTALL] and names what will happen, so nothing changes silently,
    # and answering anything else aborts before this runs.
    if (Test-StrictDocInstalled) {
        $ver = Get-StrictDocVersion

        # A pin that already matches needs no pip call at all -- comparing two
        # version strings is local and instant. Only "==X" and a bare "X" name
        # one exact version; ranges are handed to pip, which decides.
        $pinned = $null
        if ($spec -match '^==\s*(.+)$') { $pinned = $Matches[1].Trim() }
        elseif ($spec -match '^\d')     { $pinned = $spec }
        if ($pinned -and $ver -eq $pinned) {
            Write-OnboardSkip "strictdoc already installed: $ver (matches strictdoc.version='$spec')"
            return $true
        }

        # FR-343a: refuse before pip runs, not after. An open server window makes
        # pip fail halfway through -- old package already deleted, new one not
        # written -- so the cost of finding out the hard way is a broken
        # installation, while the check costs one local process enumeration.
        if (-not (Confirm-StrictDocNotRunning)) { return $false }

        if (-not $ver) {
            Write-OnboardWarn "strictdoc is on PATH but does not run (an interrupted upgrade leaves it this way)."
            Write-OnboardInfo "Reinstalling it."
        } elseif ($spec -eq "latest") {
            Write-OnboardInfo "strictdoc $ver installed; strictdoc.version='latest' - checking for a newer release..."
        } else {
            Write-OnboardInfo "strictdoc $ver installed; strictdoc.version='$spec' - applying it..."
        }

        $ok = Invoke-StrictDocPip -Python $python -Target $target -Upgrade:($spec -eq "latest")
        $after = if (Test-StrictDocInstalled) { Get-StrictDocVersion } else { $null }

        if (-not $ok -or -not $after) {
            if ($script:StrictDocPipFileLocked) {
                Show-StrictDocLockedRecovery -PreviousVersion $ver
            } else {
                Write-OnboardError "strictdoc is no longer runnable after the attempt (was $ver)."
                if ($ver) { Write-OnboardInfo "Restore with: pip install `"strictdoc==$ver`"" }
            }
            return $false
        }
        if ($after -eq $ver) {
            Write-OnboardOk "strictdoc $after (already up to date)"
        } else {
            Write-OnboardOk "strictdoc: $ver -> $after"
            Write-OnboardWarn "Version differences are listed in docs/02-sdoc-authoring.md (section 9)."
            Write-OnboardInfo "To go back: pip install `"strictdoc==$ver`""
        }
        return $true
    }

    # pip writes informational lines (e.g. "ERROR: pip's dependency resolver
    # does not currently take into account...") to stderr even when the
    # install ultimately succeeds. Combined with $ErrorActionPreference = "Stop"
    # (set globally in setup-strictdoc.ps1), the 2>&1 merge turns those into
    # terminating errors and fires the catch despite pip exiting 0. Relax EAP
    # locally and trust $LASTEXITCODE -- same pattern as Invoke-GitClone.
    Write-OnboardInfo "Upgrading pip..."
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $python -m pip install --upgrade pip --quiet 2>&1 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) {
            Write-OnboardWarn "pip upgrade returned exit $LASTEXITCODE (continuing)"
        }
    } catch {
        Write-OnboardWarn "pip upgrade threw: $($_.Exception.Message) (continuing)"
    } finally {
        $ErrorActionPreference = $oldEAP
    }

    # FR-311 / ADR-011: do NOT return early on non-zero exit -- pip emits
    # "ERROR: ..." text to stderr in many benign cases. Capture the exit
    # code, then use FR-312 / ADR-013 two-stage verification.
    # FR-343a: same guard as the reconcile branch. Reaching here normally means
    # nothing is installed, so nothing can be locked -- but a strictdoc left
    # running from another Python would still make pip fail on the shared
    # console-script name, and refusing early costs one process enumeration.
    if (-not (Confirm-StrictDocNotRunning)) { return $false }

    $pipExit = if (Invoke-StrictDocPip -Python $python -Target $target) { 0 } else { 1 }

    Update-PathFromRegistry
    $installed = Test-StrictDocInstalled
    $version   = if ($installed) { Get-StrictDocVersion } else { $null }
    $ok = Confirm-InstallResult -ExitOk ($pipExit -eq 0) `
                                -StateOk $installed `
                                -Label "strictdoc" `
                                -Version $version
    if ($ok -and $installed) {
        Write-OnboardOk "strictdoc installed: $version"
    } elseif ($script:StrictDocPipFileLocked) {
        Show-StrictDocLockedRecovery
    }
    return $ok
}

function Install-RequiredTools {
    [CmdletBinding()]
    param(
        [string]$PythonVersion = "3.13"
    )
    $results = [ordered]@{}

    # Git
    if (Test-Path Function:\Get-Command) { } # noop, just to ensure parser sees the block

    foreach ($t in $script:RequiredTools) {
        if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) {
            Write-OnboardSkip "$($t.Display) already installed"
            $results[$t.Key] = $true
            continue
        }
        $ok = Invoke-WingetInstall -Id $t.Id -DisplayName $t.Display
        Update-PathFromRegistry
        # FR-312 two-stage verification using PATH detection.
        $results[$t.Key] = Confirm-InstallResult -ExitOk $ok `
                                                 -StateOk ([bool](Get-Command $t.Cmd -ErrorAction SilentlyContinue)) `
                                                 -Label $t.Display
    }

    # Python (version-dependent winget ID)
    if (Test-PythonInstalled) {
        Write-OnboardSkip "Python already installed: $(Get-PythonCommand)"
        $results["python"] = $true
    } else {
        $pyId = if ($PythonVersion -eq "latest") { "Python.Python.3" } else { "Python.Python.$PythonVersion" }
        $ok = Invoke-WingetInstall -Id $pyId -DisplayName "Python $PythonVersion"
        Update-PathFromRegistry
        # FR-312 two-stage verification (Test-PythonInstalled excludes the
        # WindowsApps Store stub).
        $results["python"] = Confirm-InstallResult -ExitOk $ok `
                                                   -StateOk (Test-PythonInstalled) `
                                                   -Label "Python $PythonVersion"
    }

    return $results
}

function Install-ClaudeCodeExtension {
    $code = Get-VSCodeCommand
    if (-not $code) {
        Write-OnboardError "VS Code not available; cannot install Claude Code extension"
        return $false
    }
    if (Test-ClaudeCodeExtensionInstalled) {
        Write-OnboardSkip "Claude Code extension ($script:CCExtensionId) already installed"
        return $true
    }
    Write-OnboardInfo "Installing VS Code extension: $script:CCExtensionId"
    # FR-311 / ADR-011: drop EAP locally so stderr output doesn't become a
    # terminating error. FR-312 (ADR-013): verify final state with
    # Test-ClaudeCodeExtensionInstalled regardless of exit code.
    $ccExit = 1
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $code --install-extension $script:CCExtensionId --force 2>&1 | ForEach-Object {
            Write-Host "  $_"
        }
        $ccExit = $LASTEXITCODE
    } catch {
        Write-OnboardWarn "code --install-extension threw (continuing to verify): $($_.Exception.Message)"
    } finally {
        $ErrorActionPreference = $oldEAP
    }
    $present = Test-ClaudeCodeExtensionInstalled
    if ($ccExit -eq 0 -and $present) {
        Write-OnboardOk "Claude Code extension installed"
        return $true
    }
    if ($ccExit -ne 0 -and $present) {
        Write-OnboardWarn "[VERIFIED] Claude Code extension is present despite exit $ccExit"
        return $true
    }
    Write-OnboardError "Claude Code extension install did not register (exit $ccExit, not present)"
    Write-OnboardWarn "If the extension ID has changed, edit '`$script:CCExtensionId' in lib/install.ps1"
    return $false
}

# ---------------------------------------------------------------------------
# Planner (used by dryrun and auto)
# ---------------------------------------------------------------------------

function Get-InstallPlan {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path (Get-Location) "setup.config.json")
    )
    if (-not (Test-Path $ConfigPath)) {
        return @("(setup.config.json not found - run 'setup-strictdoc.bat config' first)")
    }
    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        return @("(invalid setup.config.json: $($_.Exception.Message))")
    }

    $plan = @()
    $plan += "winget install Git.Git              [required]"
    $plan += "winget install Python.Python.$($cfg.python.version)  [required]"
    $plan += "winget install GitHub.cli            [required]"
    $plan += "pip install strictdoc                [required, after Python]"

    if ($cfg.options.install_claude_winget -and $cfg.options.install_claude_npm) {
        $plan += "*** ERROR: install_claude_winget and install_claude_npm both true (FR-305) ***"
    } else {
        if ($cfg.options.install_claude_winget) { $plan += "winget install Anthropic.Claude     [optional, needs verification]" }
        if ($cfg.options.install_claude_npm)    { $plan += "winget install OpenJS.NodeJS.LTS + npm i -g @anthropic-ai/claude-code  [optional]" }
    }

    # VS Code is handled by Phase A (required); not listed here as optional.
    if ($cfg.options.install_obsidian) { $plan += "winget install Obsidian.Obsidian           [optional]" }
    if ($cfg.options.install_terminal) { $plan += "winget install Microsoft.WindowsTerminal   [optional]" }
    if ($cfg.options.install_pwsh7)    { $plan += "winget install Microsoft.PowerShell        [optional]" }
    if ($cfg.options.install_ripgrep)  { $plan += "winget install BurntSushi.ripgrep.MSVC     [optional]" }
    if ($cfg.options.install_jq)       { $plan += "winget install jqlang.jq                   [optional]" }

    if ($cfg.vscode -and $cfg.vscode.extensions) {
        foreach ($ext in $cfg.vscode.extensions) {
            $plan += "code --install-extension $ext"
        }
    }

    if ($cfg.proxy.mode -eq "local") {
        $plan += "pip install px-proxy  [proxy.mode=local]"
        $plan += "generate px.ini       [proxy.mode=local]"
    } elseif ($cfg.proxy.mode -eq "env") {
        $plan += "prompt password (Read-Host -AsSecureString), set HTTP_PROXY/HTTPS_PROXY for this process only"
    }

    return $plan
}

# ---------------------------------------------------------------------------
# Subcommand entrypoint
# ---------------------------------------------------------------------------

function Invoke-Install {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path (Get-Location) "setup.config.json"),
        [switch]$DryRun
    )
    Write-OnboardStep "Install"

    if ($DryRun) {
        $plan = Get-InstallPlan -ConfigPath $ConfigPath
        Write-OnboardInfo "Planned install actions:"
        foreach ($line in $plan) { Write-Host "  - $line" }
        return $true
    }

    Write-OnboardWarn "Direct 'install' subcommand is not fully implemented (Phase B onwards). Use 'auto' for the full flow."
    Write-OnboardInfo "Planned actions for reference:"
    $plan = Get-InstallPlan -ConfigPath $ConfigPath
    foreach ($line in $plan) { Write-Host "  - $line" }
    return $false
}

function Invoke-Upgrade {
    # FR-334: change the version of an already-installed strictdoc.
    #
    # This is the ONLY code path that changes the version of a working
    # installation. 'auto' deliberately never does (FR-309 / FR-335), so
    # re-running setup cannot alter an environment that is in use.
    #
    # No PyPI probe runs before the confirmation. Every PyPI round trip took
    # about 60 seconds on the reference machine, and a preview would double
    # that for no decision the user cannot already make: the action is
    # "move strictdoc to <spec>", and the resulting version is reported
    # afterwards along with the command that puts it back. Pass -Preview to
    # pay for the extra round trip and see the target first.
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path (Get-Location) "setup.config.json"),
        [switch]$NonInteractive,
        [switch]$Preview
    )
    Write-OnboardStep "Upgrade StrictDoc"

    $python = Get-PythonCommand
    if (-not $python) {
        Write-OnboardError "Python not found on PATH. Cannot upgrade strictdoc."
        return $false
    }

    if (-not (Test-StrictDocInstalled)) {
        Write-OnboardWarn "strictdoc is not installed - there is nothing to upgrade."
        Write-OnboardInfo "Double-click setup-strictdoc.bat to install it."
        return $false
    }

    # FR-343a: say so before the summary and the 'yes' prompt, not after pip has
    # already half-removed the package. This is the interactive path, so the
    # user is at the keyboard and can close the window and come straight back.
    if (-not (Confirm-StrictDocNotRunning)) { return $false }

    $before = Get-StrictDocVersion

    # The spec is optional: 'upgrade' works on a machine that has never had a
    # setup.config.json (someone who installed strictdoc by hand), in which
    # case it means "move to the newest release".
    $config = $null
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-OnboardWarn "Could not parse ${ConfigPath}: $($_.Exception.Message)"
            Write-OnboardWarn "Continuing with strictdoc.version='latest'."
        }
    } else {
        Write-OnboardInfo "setup.config.json not found - using strictdoc.version='latest'."
    }

    $spec   = Get-StrictDocVersionSpec -Config $config
    $target = Resolve-StrictDocPipTarget -Spec $spec
    if (-not $target) {
        Show-StrictDocSpecError -Spec $spec
        return $false
    }

    Write-Host ""
    Write-Host "  Installed now  : $before"
    Write-Host "  Configured spec: $spec"
    Write-Host "  Will run       : pip install --upgrade $target"
    Write-Host "  Verified by    : docs/04-starter-guide.md records $script:StrictDocVerifiedVersion"
    Write-Host ""
    Write-Host "  To go back afterwards: pip install `"strictdoc==$before`""
    Write-Host ""

    if ($Preview) {
        Write-OnboardInfo "Asking pip what this would install (network; can take a minute)..."
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            & $python -m pip install --upgrade $target --dry-run 2>&1 |
                Where-Object { $_ -match '^Would install' } |
                ForEach-Object { Write-Host "  $_" }
        } catch {
            Write-OnboardWarn "Preview failed (continuing): $($_.Exception.Message)"
        } finally {
            $ErrorActionPreference = $oldEAP
        }
        Write-Host ""
    }

    if ($NonInteractive) {
        Write-OnboardInfo "Non-interactive mode: skipping yes prompt"
    } else {
        $reply = Read-Host "Upgrade strictdoc? Type 'yes' to proceed, anything else to abort"
        if ($reply -ne "yes") {
            Write-OnboardWarn "Aborted - strictdoc left at $before."
            return $false
        }
    }

    # FR-343a: check again. The first check ran before the summary, and a server
    # can be started while the user reads it and answers the prompt.
    if (-not (Confirm-StrictDocNotRunning)) { return $false }

    $pipExit = if (Invoke-StrictDocPip -Python $python -Target $target -Upgrade) { 0 } else { 1 }

    # FR-312 / ADR-013: two-stage verification.
    #
    # Deliberately NO Update-PathFromRegistry here, unlike the install path.
    # An upgrade replaces the package in the same interpreter, so strictdoc.exe
    # does not move -- it was already on PATH when this function started. What
    # rebuilding PATH from the registry WOULD do is discard a PATH the caller
    # set, so a virtualenv or a non-registry Python would be upgraded and then
    # verified against a different, unchanged strictdoc. That produced a
    # confident "nothing changed" on an upgrade that had in fact succeeded.
    $installed = Test-StrictDocInstalled
    $after     = if ($installed) { Get-StrictDocVersion } else { $null }
    $ok = Confirm-InstallResult -ExitOk ($pipExit -eq 0) `
                                -StateOk $installed `
                                -Label "strictdoc" `
                                -Version $after
    if (-not $ok) {
        if ($script:StrictDocPipFileLocked) {
            Show-StrictDocLockedRecovery -PreviousVersion $before
            return $false
        }
        Write-OnboardError "Upgrade failed. strictdoc reports: $(if ($after) { $after } else { 'not runnable' })"
        Write-OnboardInfo "To restore the previous version: pip install `"strictdoc==$before`""
        return $false
    }

    Write-Host ""
    if ($after -eq $before) {
        Write-OnboardOk "strictdoc is already at $after - nothing changed."
        return $true
    }

    Write-OnboardOk "strictdoc: $before -> $after"
    Write-Host ""

    # FR-336: a version change can alter how existing documents render, so
    # point at the differences instead of leaving the user to discover them.
    # Only observed facts are stated here. The 0.23.1 -> 0.27.1 differences
    # were measured; which release introduced each one was not, so no release
    # boundary is claimed.
    Write-OnboardWarn "Version differences are listed in docs/02-sdoc-authoring.md (section 9)."
    Write-OnboardInfo "The bundled samples assume strictdoc 0.27 or newer, where MATHJAX and MERMAID"
    Write-OnboardInfo "  are on by default. Below 0.27 those toggles are required, so sample diagrams"
    Write-OnboardInfo "  show as raw text and formulas do not render."
    Write-OnboardInfo "To go back: pip install `"strictdoc==$before`""
    return $true
}
