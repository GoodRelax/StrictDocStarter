# lib/server-process.ps1 - StrictDoc server launcher engine (v1.2).
# Model: visible "strictdoc server CLI window" + auto-port + dedup + adoption re-probe.
# Spec: FR-1101..1105 (visible launch), FR-1111..1114 (stop/status),
#       FR-1156..1159 (auto-port / dedup / re-probe / browser), FR-1157c (startup-error diag).
# Output language: English ASCII only (NFR-005 / ADR-008).
#
# IMPORTANT (Glossary 1.9 / 1.7 Constraints):
#   $pid  is a PowerShell RESERVED automatic variable (current process PID).
#         Use $serverPid / $ownerPid / $targetPid for other processes.
#   $host is also reserved; use $bindHost / $urlHost for server host strings.
#
# NOTE: dot-sourced from launch-strictdoc.ps1 (not a module).

# M3: resolve strictdoc to an absolute path (FR-1105). Returns $null if not found.
function Resolve-StrictDocExecutable {
    $cmd = Get-Command strictdoc -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return $null }
    return $cmd.Source
}

function Get-BrowserOpenUrl {
    # FR-1103 / FR-1159: 0.0.0.0 and :: get rewritten to 127.0.0.1.
    param([string]$BindHost, [int]$Port)
    $urlHost = $BindHost
    if ($urlHost -eq '0.0.0.0' -or $urlHost -eq '::') { $urlHost = '127.0.0.1' }
    return ("http://{0}:{1}/" -f $urlHost, $Port)
}

function Open-BrowserAt {
    # FR-1159: open default browser at the adopted port.
    param([string]$BindHost, [int]$Port)
    $url = Get-BrowserOpenUrl -BindHost $BindHost -Port $Port
    try {
        Start-Process $url -ErrorAction Stop
        Write-Host "[INFO]  Opened browser at $url"
    } catch {
        Write-Host "[WARN]  Failed to open browser: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Get-PortListenerPid {
    # Returns OwningProcess PID of the LISTEN socket on $Port:
    #   >0  = listening, this PID owns it
    #   -1  = listening but OwningProcess not resolvable (unknown owner)
    #    0  = not listening
    # (host=0.0.0.0 can LISTEN on both IPv4/IPv6; pick first row with a valid owner.)
    param([int]$Port)
    try {
        $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ($null -eq $conns) { return 0 }
        $valid = $conns | Where-Object { $null -ne $_.OwningProcess -and [int]$_.OwningProcess -gt 0 } | Select-Object -First 1
        if ($null -ne $valid) { return [int]$valid.OwningProcess }
        if ($null -ne ($conns | Select-Object -First 1)) { return -1 }
        return 0
    } catch {
        return 0
    }
}

function Test-PidIsStrictdoc {
    # FR-1157a: the listening process is a strictdoc server (CommandLine contains "strictdoc").
    # WMI failure / empty CommandLine -> NOT strictdoc (safe side).
    param([int]$ProcessId)
    if ($ProcessId -le 0) { return $false }
    try {
        $p = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$ProcessId" -ErrorAction Stop
        if ($null -eq $p -or [string]::IsNullOrEmpty($p.CommandLine)) { return $false }
        return ($p.CommandLine -match '(?i)strictdoc')
    } catch {
        return $false
    }
}

function ConvertTo-NormalizedPath {
    # Normalize for comparison: full path, trailing separators removed, lower-case.
    # Returns $null if the input is empty or cannot be made absolute (FR-1158a).
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    try {
        $full = [System.IO.Path]::GetFullPath($Path)
    } catch {
        return $null
    }
    $full = $full.TrimEnd('\', '/')
    return $full.ToLowerInvariant()
}

function Get-RunningStrictDocServers {
    # FR-1158 / FR-1157: enumerate live 'strictdoc server' processes via CIM, parsing
    # the served input_path (best-effort) and --port from each CommandLine.
    # Returns @() of [pscustomobject]@{ Pid; Port; NormPath }.
    # Limitation (spec 6.10.3 Limitations 1): CommandLine-dependent; WMI failure -> @().
    $servers = @()
    $procs = $null
    try {
        $procs = Get-CimInstance -ClassName Win32_Process -ErrorAction Stop |
            Where-Object { $_.CommandLine -and ($_.CommandLine -match '(?i)strictdoc') -and ($_.CommandLine -match '(?i)(^|\s)server(\s|$)') }
    } catch {
        return $servers
    }
    foreach ($p in $procs) {
        $cl = $p.CommandLine
        $port = 0
        if ($cl -match '(?i)--port[\s=]+"?(\d{1,5})"?') { $port = [int]$matches[1] }
        # served path = first token after the 'server' subcommand (quoted or bare),
        # excluding option flags. Best-effort.
        $normPath = $null
        if ($cl -match '(?i)\bserver\b\s+(?:"([^"]+)"|([^\s"-][^\s"]*))') {
            $rawPath = if ($matches[1]) { $matches[1] } else { $matches[2] }
            $normPath = ConvertTo-NormalizedPath -Path $rawPath
        }
        $servers += [pscustomobject]@{ Pid = [int]$p.ProcessId; Port = $port; NormPath = $normPath }
    }
    return $servers
}

function Find-ServerPortForPath {
    # FR-1158: if a running strictdoc server already serves $ProjectPath, return its port; else 0.
    # (a) unparseable served paths are skipped (treated as no match -> new launch).
    # (b) multiple matches: smallest port. (c) enumeration failure -> 0 (-> new launch).
    param([string]$ProjectPath)
    $target = ConvertTo-NormalizedPath -Path $ProjectPath
    if ($null -eq $target) { return 0 }
    $hits = Get-RunningStrictDocServers | Where-Object { $_.NormPath -eq $target -and $_.Port -gt 0 }
    if (($hits | Measure-Object).Count -eq 0) { return 0 }
    return ([int](($hits | Sort-Object Port | Select-Object -First 1).Port))
}

function Test-StrictDocServerAliveOnPort {
    # FR-1157 (c/d): is a strictdoc server process (launched with --port $Port) still alive?
    param([int]$Port)
    $alive = Get-RunningStrictDocServers | Where-Object { $_.Port -eq $Port }
    return (($alive | Measure-Object).Count -gt 0)
}

function Get-FreePort {
    # FR-1156 / FR-1156b: first free port from $Start up to ceiling = min($Start+20, 64999).
    # Returns the free port, or 0 if none (caller emits FR-1156b error).
    param([int]$Start)
    $ceiling = [Math]::Min($Start + 20, 64999)
    for ($p = $Start; $p -le $ceiling; $p++) {
        if ((Get-PortListenerPid -Port $p) -eq 0) { return $p }
    }
    return 0
}

function Get-PortCeiling {
    param([int]$Start)
    return [Math]::Min($Start + 20, 64999)
}

function Quote-ArgIfNeeded {
    # PS 5.1 Start-Process -ArgumentList does NOT auto-quote array elements containing
    # whitespace; pre-quote so "C:\My Project" stays a single argument (FR-1133).
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    if ($Value -match '\s') { return '"' + $Value + '"' }
    return $Value
}

function Start-StrictDocCliWindow {
    # FR-1101: launch 'strictdoc server <path> --host <h> --port <p> [--output-path <o>]'
    # in an independent, visible console window (the "strictdoc server CLI window").
    #
    # Method: Start-Process on strictdoc.exe DIRECTLY. For a console app, Start-Process with
    # UseShellExecute (the default; no -NoNewWindow, no -WindowStyle Hidden) opens a NEW visible
    # console window -- verified to bind the port. We deliberately do NOT route through
    # 'cmd /c start "<title>" ...': passing that quoted command line through
    # Start-Process -ArgumentList makes PowerShell re-quote it, which corrupts cmd's parser
    # (e.g. the parenthesised title caused a cmd syntax error). No stdout/stderr redirect
    # (FR-1102: the window IS the log). The window uses the default title; the StrictDoc banner
    # inside it (Server URL: http://<host>:<port>/) identifies each window/document.
    param(
        [Parameter(Mandatory)] [string]$StrictDocExe,
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [string]$BindHost,
        [Parameter(Mandatory)] [int]$Port,
        [string]$OutputPath = ''
    )
    # FR-1106: --watch. The launcher exists so that people edit and look, so the
    # browser has to follow edits made on disk. Without it, a change in VS Code
    # shows up only after a manual reload; editing inside the StrictDoc web UI
    # already refreshes on its own, which made the difference easy to miss.
    # Neither case needs the server stopped -- the window stays up either way.
    $argList = @('server', (Quote-ArgIfNeeded $ProjectPath), '--host', $BindHost, '--port', $Port.ToString(), '--watch')

    # FR-1160: always pass --output-path, defaulting it under the served folder.
    #
    # StrictDoc's own default for `server` is the RELATIVE string "./output/server"
    # (core/project_config.py), which it resolves against the server process's
    # current working directory -- not against the served folder. This launcher
    # normalises the CWD to the StrictDocStarter root, so every project used to
    # write into <starter_root>\output\server and SHARE html\index.html plus the
    # statistics / traceability-matrix / tree-map screens. Measured on 0.27.1:
    # serving md-basic-ja on 5111 and sd-basic-ja on 5112 at the same time made
    # 5111 answer "/" with sd-basic-ja's project title and document list, because
    # the second server overwrote the shared index.html.
    #
    # The first level MUST stay named "output": StrictDoc unconditionally skips a
    # directory of that name directly under the served folder when scanning for
    # documents. Any other name is scanned, and the second run then re-reads the
    # _assets\*.sdoc copies it wrote itself and dies with
    # "OneToOneDictionary: Cannot create a link because lhs_node already exists".
    # The second level is "strictdoc" rather than "server" so it cannot collide
    # with an output\server folder the user already owns.
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path $ProjectPath 'output\strictdoc'
    }
    $argList += @('--output-path', (Quote-ArgIfNeeded $OutputPath))
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        Start-Process -FilePath $StrictDocExe -ArgumentList $argList -ErrorAction Stop
        $ErrorActionPreference = $eap
        return $true
    } catch {
        $ErrorActionPreference = $eap
        Write-Host "[ERROR] Failed to launch strictdoc server window: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Confirm-PortAdoption {
    # FR-1157: poll (1s) after launch until a definitive signal. NO fixed 8s timeout;
    # 60s is only a non-fatal safety cap. Branches:
    #   (a) port LISTEN by a strictdoc PID            -> @{ Result='adopted' }
    #   (b) port LISTEN by a non-strictdoc PID        -> @{ Result='race' }     (TOCTOU)
    #   (c) our server process gone, port not bound   -> @{ Result='failed' }   (after spawn grace)
    #   (d) our server alive but not yet bound        -> keep waiting (no false-fail on big projects)
    #   safety cap reached                            -> @{ Result='timeout' }
    # SpawnGraceSec: how long to allow for the process to FIRST appear (strictdoc.exe ->
    # python cold start can take several seconds before it is queryable via CIM).
    param([int]$Port, [int]$SpawnGraceSec = 12, [int]$MaxWaitSec = 60)
    $startTime = Get-Date
    $everSeenAlive = $false
    while ($true) {
        $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
        $ownerPid = Get-PortListenerPid -Port $Port
        if ($ownerPid -gt 0) {
            if (Test-PidIsStrictdoc -ProcessId $ownerPid) {
                return [pscustomobject]@{ Result = 'adopted'; OwnerPid = $ownerPid }     # (a)
            }
            return [pscustomobject]@{ Result = 'race'; OwnerPid = $ownerPid }            # (b)
        }
        if ($ownerPid -lt 0) {
            # LISTEN but owner unresolvable: cannot confirm strictdoc -> treat as race (safe).
            return [pscustomobject]@{ Result = 'race'; OwnerPid = 0 }
        }
        # Not listening yet. Classify by whether our server process is alive.
        if (Test-StrictDocServerAliveOnPort -Port $Port) {
            $everSeenAlive = $true            # (d) alive but unbound -> keep waiting (big projects)
        } else {
            if ($everSeenAlive) {
                # appeared then vanished without binding -> startup failure (e.g. parse error).
                return [pscustomobject]@{ Result = 'failed'; OwnerPid = 0 }               # (c)
            }
            if ($elapsed -ge $SpawnGraceSec) {
                # never appeared within the spawn grace -> launch failed.
                return [pscustomobject]@{ Result = 'failed'; OwnerPid = 0 }               # (c)
            }
            # still within spawn grace and not seen yet -> wait
        }
        if ($elapsed -ge $MaxWaitSec) {
            return [pscustomobject]@{ Result = 'timeout'; OwnerPid = 0 }
        }
        Start-Sleep -Seconds 1
    }
}

function Show-StartupErrorDiagnostic {
    # FR-1157c: the CLI window may have closed on a parse error, so surface the cause
    # HERE in the manage cmd window. Run a synchronous 'strictdoc export' (a .sdoc parse
    # error fails fast at the parse stage) and echo its output. Temp dir is cleaned.
    # strictdoc-not-found cannot reach here (FR-1105 aborts earlier). If export fails for a
    # non-parse reason, its output is echoed verbatim without asserting the cause.
    param(
        [Parameter(Mandatory)] [string]$StrictDocExe,
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [int]$Port
    )
    Write-Host ""
    Write-Host "[ERROR] StrictDoc server failed to start on port $Port (it exited before binding)." -ForegroundColor Red
    Write-Host "        Most likely a .sdoc parse error. Details from 'strictdoc export':" -ForegroundColor Red
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("sds-diag-" + [Guid]::NewGuid().ToString('N'))
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & $StrictDocExe export $ProjectPath --output-dir $tmp 2>&1
        $ErrorActionPreference = $eap
        $text = ($out | Out-String)
        $lines = $text -split "`r?`n" | Where-Object { $_ -match '(?i)(error|could not parse|TextXSyntaxError|traceback|exception|line\s+\d+)' }
        if (($lines | Measure-Object).Count -gt 0) {
            foreach ($ln in ($lines | Select-Object -First 15)) {
                Write-Host ("        " + $ln.Trim()) -ForegroundColor Yellow
            }
        } else {
            # No recognizable error lines: echo the tail so the user sees something useful.
            $tail = $text.Trim()
            if ($tail.Length -gt 600) { $tail = $tail.Substring($tail.Length - 600) }
            if ($tail.Length -gt 0) { Write-Host ("        " + $tail) -ForegroundColor Yellow }
            else { Write-Host "        (no diagnostic output captured; run 'strictdoc server' manually to see the error)" -ForegroundColor Yellow }
        }
    } catch {
        $ErrorActionPreference = $eap
        Write-Host "        (diagnostic export could not run: $($_.Exception.Message))" -ForegroundColor Yellow
    } finally {
        if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "        Fix the .sdoc and re-drop the folder." -ForegroundColor Red
}
