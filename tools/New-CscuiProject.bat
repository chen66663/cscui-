@echo off
setlocal EnableExtensions

rem Canonical Windows entry point. The PowerShell implementation owns all
rem validation and file operations so local and CI behavior stay identical.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0New-CscuiProject.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
