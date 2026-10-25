@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0TrayColorPicker.ps1"
echo.
echo If an error appeared above, copy it and send it to ChatGPT.
pause
