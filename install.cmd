@echo off
setlocal
rem EchoVRCE Switcher installer: copies the switcher to a folder of its own,
rem puts a shortcut on the desktop and opens it. Re-run it to update.
set "DEST=%LOCALAPPDATA%\EchoVRCE-Switcher"
set "FAILED="
echo Installing EchoVRCE Switcher to %DEST% ...
if not exist "%DEST%" mkdir "%DEST%"
for %%F in (Switch.bat switcher.ps1 mode-watch.ps1 inject.exe server.txt README-PLAYERS.txt echo_gravity_client.dll echo_speed_client.dll echo_tiny_client.dll echo_strength_client.dll echo_stretch_client.dll echo_blink_client.dll echo_web_client.dll) do (
  copy /Y "%~dp0%%F" "%DEST%\%%F" >nul || set "FAILED=1"
)
if defined FAILED (
  echo.
  echo Some files could not be replaced - Echo VR is probably still running.
  echo Close Echo VR completely, then run this installer again.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = (New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop') + '\EchoVRCE Switcher.lnk'); $s.TargetPath = '%DEST%\Switch.bat'; $s.WorkingDirectory = '%DEST%'; $s.Save()"
echo Done. Opening the switcher (there is also an "EchoVRCE Switcher" shortcut on your desktop).
start "" /D "%DEST%" "%DEST%\Switch.bat"
exit /b 0
