@echo off
rem winarchy CLI shim (this folder is on your user PATH after install).
set "OW_PWSH=pwsh.exe"
where pwsh.exe >nul 2>&1 || set "OW_PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
"%OW_PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0winarchy.ps1" %*
