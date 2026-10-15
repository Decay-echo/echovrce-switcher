# EchoVRCE Switcher - points an Echo VR install at a chosen server, and back.
# Windows PowerShell 5.1 + WinForms. Launched by Switch.bat (which sets -STA).
#
# The server address is NOT baked into this tool. The host gives it to you
# privately (e.g. in their Discord); you paste it once and it's remembered on
# THIS PC only, in my-server.txt next to the tool. Nothing here is published.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Root       = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerFile = Join-Path $Root 'server.txt'
$MyAddrFile = Join-Path $Root 'my-server.txt'
$PathMemo   = Join-Path $Root 'echo-exe.txt'
$Token      = 'defaultkey'
$BackupName = 'config.original-backup.json'

function Read-Line($path) {
    if (-not (Test-Path $path)) { return '' }
    foreach ($line in Get-Content $path) {
        $t = $line.Trim()
        if ($t -ne '' -and -not $t.StartsWith('#')) { return $t }
    }
    return ''
}

function Normalize-Addr($a) {
    $a = $a.Trim()
    if ($a -eq '') { return '' }
    $a = $a -replace '^wss?://','' -replace '^https?://',''
    $a = ($a -split '/')[0]
    if ($a -notmatch ':') { $a = "$a`:7350" }
    return $a
}

function Current-Addr {
    $a = Read-Line $MyAddrFile
    if ($a -ne '') { return $a }
    return Read-Line $ServerFile
}
function Save-Addr($a) { Set-Content -Path $MyAddrFile -Value $a -NoNewline -Encoding ascii }

# Find echovr.exe. Returns the full path to the exe, or $null.
function Find-EchoExe {
    $cands = @()
    if (Test-Path $PathMemo) { $cands += (Get-Content $PathMemo -Raw).Trim() }
    $cands += @(
        'C:\echo\EchoBinarys\bin\win10\echovr.exe',
        (Join-Path $env:ProgramFiles       'Oculus\Software\Software\ready-at-dawn-echo-arena\bin\win10\echovr.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Oculus\Software\Software\ready-at-dawn-echo-arena\bin\win10\echovr.exe')
    )
    foreach ($c in $cands) { if ($c -and (Test-Path $c)) { return $c } }
    return $null
}
function Save-EchoExe($exe) { Set-Content -Path $PathMemo -Value $exe -NoNewline -Encoding ascii }

# From echovr.exe (…\bin\win10\echovr.exe) derive the install root (…).
function Root-Of($exe) { Split-Path (Split-Path (Split-Path $exe -Parent) -Parent) -Parent }

# The config.json the game actually reads can sit in _local at the install root
# or next to the exe. Prefer whichever already exists; else default to root\_local.
function Config-Path($exe) {
    $root = Root-Of $exe
    $exeDir = Split-Path $exe -Parent
    foreach ($p in @((Join-Path $root '_local\config.json'), (Join-Path $exeDir '_local\config.json'))) {
        if (Test-Path $p) { return $p }
    }
    return (Join-Path $root '_local\config.json')
}
function Backup-Path($cfg) { Join-Path (Split-Path $cfg -Parent) $BackupName }

function Target-Of($exe) {
    $cfg = Config-Path $exe
    if (-not (Test-Path $cfg)) { return 'no config yet' }
    try { $o = Get-Content $cfg -Raw | ConvertFrom-Json } catch { return 'unreadable config' }
    $h = [string]$o.serverdb_host
    if ($h -match 'echovrce\.com') { return 'EchoVRCE (official)' }
    if ($h -match '://([^/?]+)')   { return $Matches[1] }
    return 'unknown'
}

function Write-ServerConfig($exe, $hostPort) {
    $cfg = Config-Path $exe
    $dir = Split-Path $cfg -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bak = Backup-Path $cfg
    if ((Test-Path $cfg) -and -not (Test-Path $bak)) { Copy-Item $cfg $bak -Force }
    $ws = "ws://$hostPort/ws?format=evr&token=$Token"
    $json = @"
{
    "apiservice_host": "http://$hostPort",
    "configservice_host": "$ws",
    "loginservice_host": "$ws",
    "matchingservice_host": "$ws",
    "serverdb_host": "$ws",
    "transactionservice_host": "$ws",
    "publisher_lock": "echovrce"
}
"@
    Set-Content -Path $cfg -Value $json -Encoding ascii
    return $cfg
}

function Restore-Original($exe) {
    $cfg = Config-Path $exe
    $bak = Backup-Path $cfg
    if (-not (Test-Path $bak)) { return $false }
    Copy-Item $bak $cfg -Force
    return $true
}

# ---------------------------------------------------------------- UI
$echoExe = Find-EchoExe

$form = New-Object System.Windows.Forms.Form
$form.Text = 'EchoVRCE Switcher'
$form.Size = New-Object System.Drawing.Size(470, 430)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(32, 34, 37)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'EchoVRCE Server Switcher'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true; $title.Location = New-Object System.Drawing.Point(20, 14)
$form.Controls.Add($title)

$lblAddr = New-Object System.Windows.Forms.Label
$lblAddr.Text = 'Server address (paste what the host gave you):'
$lblAddr.AutoSize = $true; $lblAddr.Location = New-Object System.Drawing.Point(22, 52)
$form.Controls.Add($lblAddr)

$txtAddr = New-Object System.Windows.Forms.TextBox
$txtAddr.Size = New-Object System.Drawing.Size(410, 26)
$txtAddr.Location = New-Object System.Drawing.Point(22, 76)
$txtAddr.Text = Current-Addr
$form.Controls.Add($txtAddr)

$lblNow = New-Object System.Windows.Forms.Label
$lblNow.AutoSize = $true; $lblNow.MaximumSize = New-Object System.Drawing.Size(420, 0)
$lblNow.Location = New-Object System.Drawing.Point(22, 110)
$form.Controls.Add($lblNow)

$btnFind = New-Object System.Windows.Forms.Button
$btnFind.Text = 'Find echovr.exe...'
$btnFind.Size = New-Object System.Drawing.Size(410, 30)
$btnFind.Location = New-Object System.Drawing.Point(22, 140)
$btnFind.BackColor = [System.Drawing.Color]::FromArgb(60, 63, 68); $btnFind.FlatStyle = 'Flat'
$form.Controls.Add($btnFind)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = 'Connect to this server'
$btnConnect.Size = New-Object System.Drawing.Size(200, 52)
$btnConnect.Location = New-Object System.Drawing.Point(22, 180)
$btnConnect.BackColor = [System.Drawing.Color]::FromArgb(88, 101, 242); $btnConnect.FlatStyle = 'Flat'
$form.Controls.Add($btnConnect)

$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = 'Go Back (undo)'
$btnBack.Size = New-Object System.Drawing.Size(190, 52)
$btnBack.Location = New-Object System.Drawing.Point(238, 180)
$btnBack.BackColor = [System.Drawing.Color]::FromArgb(79, 84, 92); $btnBack.FlatStyle = 'Flat'
$form.Controls.Add($btnBack)

$lg = New-Object System.Windows.Forms.TextBox
$lg.Multiline = $true; $lg.ReadOnly = $true; $lg.ScrollBars = 'Vertical'
$lg.Size = New-Object System.Drawing.Size(410, 120)
$lg.Location = New-Object System.Drawing.Point(22, 244)
$lg.BackColor = [System.Drawing.Color]::FromArgb(24, 25, 28); $lg.ForeColor = [System.Drawing.Color]::Gainsboro
$form.Controls.Add($lg)

function Say($m) { $lg.AppendText((Get-Date -Format 'HH:mm:ss') + '  ' + $m + "`r`n") }

function Refresh-State {
    if ($echoExe -and (Test-Path $echoExe)) {
        $lblNow.Text = "Echo found. Currently pointed at:  " + (Target-Of $echoExe)
        $lblNow.ForeColor = [System.Drawing.Color]::Gainsboro
    } else {
        $lblNow.Text = 'Echo VR not found - click "Find echovr.exe..." and pick it.'
        $lblNow.ForeColor = 'Orange'
    }
}

function Pick-Exe {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Find echovr.exe (inside your Echo VR folder, under bin\win10)'
    $dlg.Filter = 'echovr.exe|echovr.exe|All programs (*.exe)|*.exe'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $false }
    if ((Split-Path $dlg.FileName -Leaf) -ne 'echovr.exe') {
        Say 'Please pick the file named echovr.exe.'; return $false
    }
    $script:echoExe = $dlg.FileName
    Save-EchoExe $echoExe
    Say "Using: $echoExe"
    return $true
}

$btnFind.Add_Click({ if (Pick-Exe) { Refresh-State } })

$btnConnect.Add_Click({
    $addr = Normalize-Addr $txtAddr.Text
    if ($addr -eq '') { Say 'Enter the server address the host gave you first.'; return }
    $txtAddr.Text = $addr
    if (-not ($echoExe -and (Test-Path $echoExe))) {
        Say 'Find echovr.exe first.'
        if (-not (Pick-Exe)) { return }
    }
    try {
        $cfg = Write-ServerConfig $echoExe $addr
        Save-Addr $addr
        Say "Connected. Game now points at $addr."
        Say "(wrote $cfg)"
        Say 'Start Echo VR. First time, use the link code with /link-headset in Discord.'
    } catch { Say "Could not write config: $($_.Exception.Message)" }
    Refresh-State
})

$btnBack.Add_Click({
    if (-not ($echoExe -and (Test-Path $echoExe))) { Say 'Find echovr.exe first.'; if (-not (Pick-Exe)) { return } }
    try {
        if (Restore-Original $echoExe) { Say 'Restored your original config. Like it never happened.' }
        else { Say 'No backup found yet - nothing to undo (Connect makes one first).' }
    } catch { Say "Could not restore: $($_.Exception.Message)" }
    Refresh-State
})

Refresh-State
Say 'Close Echo VR before switching, then re-open it after.'

if ($env:ECHO_SWITCHER_SELFTEST -eq '1') {
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1200
    $timer.Add_Tick({ $timer.Stop(); $form.Close() })
    $timer.Start()
}

[void]$form.ShowDialog()
