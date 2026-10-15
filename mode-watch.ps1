# Background helper: makes a game-mode mod "just happen" whenever Echo VR runs.
# You never run anything by hand while Echo is open - the switcher starts this for
# you (and re-starts it at logon) when you pick a mode that has a mod. It injects
# the given DLL into echovr.exe whenever the game is running, including restarts.
# Turn it off with the switcher's "Back to EchoVRCE" button.

param([Parameter(Mandatory = $true)][string]$Dll)

$ErrorActionPreference = 'Continue'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inject   = Join-Path $dir 'inject.exe'
$dllPath  = Join-Path $dir $Dll
$pidFile  = Join-Path $dir 'mode-watch.pid'
$stopFlag = Join-Path $dir 'mode-watch.stop'

if (-not (Test-Path $inject) -or -not (Test-Path $dllPath)) { exit 1 }

# Single instance: if a watcher is already running (e.g. started at logon, or by a
# previous Connect) this one exits quietly so we never double up.
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\EchoVRCE_ModeWatch', [ref]$createdNew)
if (-not $createdNew) { exit 0 }

Set-Content -Path $pidFile -Value $PID -NoNewline -Encoding ascii
Remove-Item $stopFlag -Force -ErrorAction SilentlyContinue

try {
    while ($true) {
        if (Test-Path $stopFlag) { Remove-Item $stopFlag -Force -ErrorAction SilentlyContinue; break }
        foreach ($p in @(Get-Process echovr -ErrorAction SilentlyContinue)) {
            $has = $false
            try { $has = [bool]($p.Modules | Where-Object { $_.ModuleName -eq $Dll }) } catch {}
            if (-not $has) { & $inject $dllPath echovr.exe | Out-Null }
        }
        Start-Sleep -Seconds 3
    }
} finally {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    $mutex.ReleaseMutex() 2>$null
    $mutex.Dispose()
}
