# EchoVRCE Switcher - point Echo VR at a community server with a chosen game mode,
# and get back to official EchoVRCE in one click.
# Windows PowerShell 5.1 + WinForms. Launched by Switch.bat (which sets -STA).
#
# The server address is not baked into the public build: the host gives it to you
# privately and you paste it once (remembered on this PC only). A personal build may
# set $BakedCreds so the host's own account logs in automatically.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Root       = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerFile = Join-Path $Root 'server.txt'
$MyAddrFile = Join-Path $Root 'my-server.txt'
$PathMemo   = Join-Path $Root 'echo-exe.txt'
$ModeMemo   = Join-Path $Root 'my-mode.txt'
$WatchPid   = Join-Path $Root 'mode-watch.pid'
$StopFlag   = Join-Path $Root 'mode-watch.stop'
$StartupCmd = Join-Path ([Environment]::GetFolderPath('Startup')) 'EchoVRCE-Mode.cmd'
$Token      = 'defaultkey'
$BackupName = 'config.original-backup.json'
# PERSONAL BUILDS ONLY: "discordid=..&password=.." so the host account logs in.
$BakedCreds = ''

# Game modes: name -> client mod DLL ('' = no mod, stock physics). Add future
# modes here and bundle their DLL next to this script; the dropdown updates itself.
$Modes = [ordered]@{
    'Normal (stock physics)' = ''
    'Gravity'                = 'echo_gravity_client.dll'
    'Super Speed'            = 'echo_speed_client.dll'
    # Experimental: you are 3x smaller in your own
    # headset (step 1 - view only; your body, hitboxes and how others see you
    # come later).
    'Tiny (experimental)'    = 'echo_tiny_client.dll'
    # Experimental: faster throws, longer stuns
    # from your punches (picking players up comes later).
    'Strength (experimental)' = 'echo_strength_client.dll'
    # Experimental: hold X / A for 5x arms
    # (2.5x each with both); grab far, let go of the button to reel in.
    'Stretch (experimental)'  = 'echo_stretch_client.dll'
    # Experimental: A = invisible 5 s, X = blink
    # where you look; 10 s cooldowns. Both 1v1 players need Blink for the
    # invisibility to hide you.
    'Blink (experimental)'    = 'echo_blink_client.dll'
    # Experimental: hold X / A to web, swing
    # around the anchor keeping your speed, grip to reel in.
    'Spider-Man (experimental)' = 'echo_web_client.dll'
}

function Read-Line($path) {
    if (-not (Test-Path $path)) { return '' }
    foreach ($line in Get-Content $path) { $t = $line.Trim(); if ($t -ne '' -and -not $t.StartsWith('#')) { return $t } }
    return ''
}
function Normalize-Addr($a) {
    $a = $a.Trim(); if ($a -eq '') { return '' }
    $a = $a -replace '^wss?://','' -replace '^https?://',''; $a = ($a -split '/')[0]
    if ($a -notmatch ':') { $a = "$a`:7350" }; return $a
}
function Current-Addr { $a = Read-Line $MyAddrFile; if ($a -ne '') { return $a }; return Read-Line $ServerFile }
function Save-Addr($a) { Set-Content -Path $MyAddrFile -Value $a -NoNewline -Encoding ascii }
function Save-Mode($m) { Set-Content -Path $ModeMemo -Value $m -NoNewline -Encoding ascii }

function Find-EchoExe {
    $cands = @()
    if (Test-Path $PathMemo) { $cands += (Get-Content $PathMemo -Raw).Trim() }
    $sub = 'Software\Software\ready-at-dawn-echo-arena\bin\win10\echovr.exe'
    $cands += 'C:\echo\EchoBinarys\bin\win10\echovr.exe'
    foreach ($pf in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($pf) { $cands += (Join-Path $pf "Meta Horizon\$sub"); $cands += (Join-Path $pf "Oculus\$sub") }
    }
    foreach ($c in $cands) { if ($c -and (Test-Path $c)) { return $c } }
    return $null
}
function Save-EchoExe($exe) { Set-Content -Path $PathMemo -Value $exe -NoNewline -Encoding ascii }
function Root-Of($exe) { Split-Path (Split-Path (Split-Path $exe -Parent) -Parent) -Parent }
function Config-Path($exe) {
    $root = Root-Of $exe; $exeDir = Split-Path $exe -Parent
    foreach ($p in @((Join-Path $root '_local\config.json'), (Join-Path $exeDir '_local\config.json'))) { if (Test-Path $p) { return $p } }
    return (Join-Path $root '_local\config.json')
}
function Backup-Path($cfg) { Join-Path (Split-Path $cfg -Parent) $BackupName }
function Target-Of($exe) {
    $cfg = Config-Path $exe; if (-not (Test-Path $cfg)) { return 'no config yet' }
    try { $o = Get-Content $cfg -Raw | ConvertFrom-Json } catch { return 'unreadable config' }
    $h = [string]$o.serverdb_host
    if ($h -match 'echovrce\.com') { return 'EchoVRCE (official)' }
    if ($h -match '://([^/?]+)') { return $Matches[1] }
    return 'unknown'
}
function Write-ServerConfig($exe, $hostPort) {
    $cfg = Config-Path $exe; $dir = Split-Path $cfg -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bak = Backup-Path $cfg
    if ((Test-Path $cfg) -and -not (Test-Path $bak)) { Copy-Item $cfg $bak -Force }
    $ws = "ws://$hostPort/ws?format=evr&token=$Token"
    $login = $ws
    $creds = if ($BakedCreds -ne '') { $BakedCreds } else { Read-Line (Join-Path $Root 'my-login.txt') }
    if ($creds -ne '') { $login = "$ws&$creds" }
    $json = @"
{
    "apiservice_host": "http://$hostPort",
    "configservice_host": "$ws",
    "loginservice_host": "$login",
    "matchingservice_host": "$ws",
    "serverdb_host": "$ws",
    "transactionservice_host": "$ws",
    "publisher_lock": "echovrce"
}
"@
    Set-Content -Path $cfg -Value $json -Encoding ascii
}
function Restore-Original($exe) {
    $cfg = Config-Path $exe; $bak = Backup-Path $cfg
    if (-not (Test-Path $bak)) { return $false }
    Copy-Item $bak $cfg -Force; return $true
}
function Stop-ModeWatcher {
    # Stop it auto-starting at logon, then stop EVERY running watcher, matched
    # by command line and not only by our PID file. A watcher started from an
    # older copy of this folder (at logon, before the folder was replaced) is
    # not in our PID file; left running it keeps the single-instance mutex, so
    # the new mode's watcher exits at once and the OLD mod keeps being injected
    # (seen switching Gravity -> Speed Test). Wait for each to exit so the mutex
    # is free before Start-ModeWatcher launches the next one.
    Remove-Item $StartupCmd -Force -ErrorAction SilentlyContinue
    Set-Content -Path $StopFlag -Value 'stop' -NoNewline -Encoding ascii
    $ids = @()
    if (Test-Path $WatchPid) { try { $ids += [int](Get-Content $WatchPid -Raw) } catch {} }
    $ids += @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*mode-watch.ps1*' } | ForEach-Object { [int]$_.ProcessId })
    foreach ($id in ($ids | Select-Object -Unique)) {
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $id -Timeout 5 -ErrorAction SilentlyContinue
    }
    Remove-Item $WatchPid -Force -ErrorAction SilentlyContinue
}
function Start-ModeWatcher($dll) {
    Stop-ModeWatcher
    if ($dll -eq '') { return }
    Remove-Item $StopFlag -Force -ErrorAction SilentlyContinue
    $w = Join-Path $Root 'mode-watch.ps1'
    # Re-arm at every logon so gravity just happens whenever Echo starts, with no
    # manual step. The "Back to EchoVRCE" button removes this file again.
    $cmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$w`" -Dll $dll`r`n"
    try { Set-Content -Path $StartupCmd -Value $cmd -Encoding ascii } catch {}
    $proc = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru `
        -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$w`"",'-Dll',$dll)
    Set-Content -Path $WatchPid -Value $proc.Id -NoNewline -Encoding ascii
}

# ---------------------------------------------------------------- UI
$echoExe = Find-EchoExe

$form = New-Object System.Windows.Forms.Form
$form.Text = 'EchoVRCE Switcher'
$form.Size = New-Object System.Drawing.Size(480, 470)
$form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(32, 34, 37); $form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'EchoVRCE Switcher'; $title.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true; $title.Location = New-Object System.Drawing.Point(20, 14); $form.Controls.Add($title)

$lblAddr = New-Object System.Windows.Forms.Label
$lblAddr.Text = 'Server address (from the host):'; $lblAddr.AutoSize = $true
$lblAddr.Location = New-Object System.Drawing.Point(22, 50); $form.Controls.Add($lblAddr)
$txtAddr = New-Object System.Windows.Forms.TextBox
$txtAddr.Size = New-Object System.Drawing.Size(420, 26); $txtAddr.Location = New-Object System.Drawing.Point(22, 72)
$txtAddr.Text = Current-Addr; $form.Controls.Add($txtAddr)

$lblMode = New-Object System.Windows.Forms.Label
$lblMode.Text = 'Game mode:'; $lblMode.AutoSize = $true
$lblMode.Location = New-Object System.Drawing.Point(22, 108); $form.Controls.Add($lblMode)
$cboMode = New-Object System.Windows.Forms.ComboBox
$cboMode.DropDownStyle = 'DropDownList'; $cboMode.Size = New-Object System.Drawing.Size(420, 28)
$cboMode.Location = New-Object System.Drawing.Point(22, 130)
foreach ($k in $Modes.Keys) { [void]$cboMode.Items.Add($k) }
$savedMode = Read-Line $ModeMemo
if ($savedMode -ne '' -and $cboMode.Items.Contains($savedMode)) { $cboMode.SelectedItem = $savedMode } else { $cboMode.SelectedIndex = 0 }
$form.Controls.Add($cboMode)

$lblNow = New-Object System.Windows.Forms.Label
$lblNow.AutoSize = $true; $lblNow.MaximumSize = New-Object System.Drawing.Size(430, 0)
$lblNow.Location = New-Object System.Drawing.Point(22, 166); $form.Controls.Add($lblNow)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = 'Connect to this server'; $btnConnect.Size = New-Object System.Drawing.Size(420, 46)
$btnConnect.Location = New-Object System.Drawing.Point(22, 196)
$btnConnect.BackColor = [System.Drawing.Color]::FromArgb(88, 101, 242); $btnConnect.FlatStyle = 'Flat'; $form.Controls.Add($btnConnect)

# Prominent, always-visible way back to the official service.
$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = 'Back to EchoVRCE (official)'; $btnBack.Size = New-Object System.Drawing.Size(420, 46)
$btnBack.Location = New-Object System.Drawing.Point(22, 250)
$btnBack.BackColor = [System.Drawing.Color]::FromArgb(59, 165, 93); $btnBack.FlatStyle = 'Flat'
$btnBack.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold); $form.Controls.Add($btnBack)

$lg = New-Object System.Windows.Forms.TextBox
$lg.Multiline = $true; $lg.ReadOnly = $true; $lg.ScrollBars = 'Vertical'
$lg.Size = New-Object System.Drawing.Size(420, 110); $lg.Location = New-Object System.Drawing.Point(22, 308)
$lg.BackColor = [System.Drawing.Color]::FromArgb(24, 25, 28); $lg.ForeColor = [System.Drawing.Color]::Gainsboro; $form.Controls.Add($lg)
function Say($m) { $lg.AppendText((Get-Date -Format 'HH:mm:ss') + '  ' + $m + "`r`n") }

function Refresh-State {
    if ($echoExe -and (Test-Path $echoExe)) { $lblNow.Text = 'Echo found. Currently pointed at:  ' + (Target-Of $echoExe); $lblNow.ForeColor = [System.Drawing.Color]::Gainsboro }
    else { $lblNow.Text = 'Echo VR not found - Connect will ask you to pick echovr.exe.'; $lblNow.ForeColor = 'Orange' }
}
function Pick-Exe {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Find echovr.exe (inside your Echo VR folder, under bin\win10)'
    $dlg.Filter = 'echovr.exe|echovr.exe|All programs (*.exe)|*.exe'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $false }
    if ((Split-Path $dlg.FileName -Leaf) -ne 'echovr.exe') { Say 'Please pick the file named echovr.exe.'; return $false }
    $script:echoExe = $dlg.FileName; Save-EchoExe $echoExe; Say "Using: $echoExe"; return $true
}

$btnConnect.Add_Click({
    $addr = Normalize-Addr $txtAddr.Text
    if ($addr -eq '') { Say 'Enter the server address the host gave you first.'; return }
    $txtAddr.Text = $addr
    if (-not ($echoExe -and (Test-Path $echoExe))) { Say 'Find echovr.exe first.'; if (-not (Pick-Exe)) { return } }
    $mode = [string]$cboMode.SelectedItem
    $dll = [string]$Modes[$mode]
    try {
        Write-ServerConfig $echoExe $addr
        Save-Addr $addr; Save-Mode $mode
        Start-ModeWatcher $dll
        Say "Connected to $addr  -  mode: $mode."
        if ($dll -ne '') { Say 'Just launch Echo VR - gravity turns on by itself, every time. Nothing to run.' }
        else { Say 'Launch Echo VR. (No mod for this mode.)' }
        Say 'First time: use the link code with /link-headset in Discord.'
    } catch { Say "Could not connect: $($_.Exception.Message)" }
    Refresh-State
})
$btnBack.Add_Click({
    if (-not ($echoExe -and (Test-Path $echoExe))) { if (-not (Pick-Exe)) { return } }
    Stop-ModeWatcher
    try {
        if (Restore-Original $echoExe) { Say 'Back on EchoVRCE (official). Mods off, auto-start removed. Restart Echo VR.' }
        else { Say 'No saved original to restore (you may not have connected yet).' }
    } catch { Say "Could not restore: $($_.Exception.Message)" }
    Refresh-State
})

Refresh-State
Say 'Pick a mode and Connect, or click Back to EchoVRCE to return to official.'
Say 'Close Echo VR before switching, then re-open it after.'

if ($env:ECHO_SWITCHER_SELFTEST -eq '1') {
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 1200
    $timer.Add_Tick({ $timer.Stop(); $form.Close() }); $timer.Start()
}
[void]$form.ShowDialog()
