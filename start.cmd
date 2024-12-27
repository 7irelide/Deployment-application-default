@echo off

powershell.exe -file "%~dp0\Install_Pack.ps1" -ExecutionPolicy ByPass

echo Appuyer sur une touche pour lancer le reboot.
pause >nul

shutdown -r -t 0
