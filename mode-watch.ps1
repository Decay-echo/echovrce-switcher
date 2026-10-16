# Background helper: makes a game-mode mod "just happen" whenever Echo VR runs.
# You never run anything by hand while Echo is open - the switcher starts this for
# you (and re-starts it at logon) when you pick a mode that has a mod. It injects
# the given DLL into echovr.exe whenever the game is running, including restarts.
# Turn it off with the switcher's "Back to EchoVRCE" button.
#
# Kept cheap for slow PCs: each second it only asks Windows whether an
# echovr.exe is running (Get-Process). The expensive part - reading the command
# line and the loaded-module list - runs once per new Echo process, not on
# every pass. (It used to run every 3 s for as long as Echo was open.) Checking
# every second also gets the mod in early, before Echo reads things it only
# reads at startup (the Tiny mode's eye offsets).

# -Dll is one DLL name, or several separated by commas (a mode plus a
# diagnostic probe); each is injected.
param([Parameter(Mandatory = $true)][string]$Dll)

$ErrorActionPreference = 'Continue'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inject   = Join-Path $dir 'inject.exe'
# A DLL missing from the folder is skipped, not fatal: a mode saved by an older
# copy of this folder (e.g. a since-removed test probe) still gets its mod.
$dlls     = @($Dll -split ',' | ForEach-Object { $_.Trim() } |
              Where-Object { $_ -ne '' -and (Test-Path (Join-Path $dir $_)) })
$pidFile  = Join-Path $dir 'mode-watch.pid'
$stopFlag = Join-Path $dir 'mode-watch.stop'

if (-not (Test-Path $inject) -or $dlls.Count -eq 0) { exit 1 }

# Single instance: if a watcher is already running (e.g. started at logon, or by a
# previous Connect) this one exits quietly so we never double up.
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\EchoVRCE_ModeWatch', [ref]$createdNew)
if (-not $createdNew) { exit 0 }

Set-Content -Path $pidFile -Value $PID -NoNewline -Encoding ascii
Remove-Item $stopFlag -Force -ErrorAction SilentlyContinue

# Echo processes already dealt with (modded, or a server we must not touch).
$done = @{}
try {
    while ($true) {
        if (Test-Path $stopFlag) { Remove-Item $stopFlag -Force -ErrorAction SilentlyContinue; break }
        $running = @(Get-Process -Name 'echovr' -ErrorAction SilentlyContinue)
        foreach ($p in $running) {
            if ($done.ContainsKey($p.Id)) { continue }
            # Inject the PLAYER mod only into a VR client - never a headless
            # dedicated server (launched with -headless/-server). Putting the
            # client's player hook into the host server pollutes it; the host
            # uses its own server DLL via the desktop launcher instead.
            $cp = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue
            if (-not $cp) { continue }
            if ([string]$cp.CommandLine -match '(?i)(^|\s)-(headless|server)(\s|$)') { $done[$p.Id] = $true; continue }
            $loaded = @()
            try { $loaded = @($p.Modules | ForEach-Object { $_.ModuleName }) } catch {}
            # By pid, not name: by name the injector takes the first echovr.exe
            # it finds, which on a hosting PC can be a headless server.
            foreach ($d in $dlls) {
                if ($loaded -notcontains $d) { & $inject (Join-Path $dir $d) $p.Id | Out-Null }
            }
            # Only call it done once every DLL is confirmed loaded; a process
            # still starting up can refuse, and is retried next pass.
            $p.Refresh()
            $loaded = @()
            try { $loaded = @($p.Modules | ForEach-Object { $_.ModuleName }) } catch {}
            if (@($dlls | Where-Object { $loaded -notcontains $_ }).Count -eq 0) { $done[$p.Id] = $true }
        }
        # Forget exited processes, so a reused pid is not skipped.
        foreach ($id in @($done.Keys)) { if (-not ($running | Where-Object Id -eq $id)) { $done.Remove($id) } }
        Start-Sleep -Seconds 1
    }
} finally {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    $mutex.ReleaseMutex() 2>$null
    $mutex.Dispose()
}
