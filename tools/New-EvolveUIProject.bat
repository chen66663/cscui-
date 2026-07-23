@echo off
setlocal EnableExtensions
echo [DEPRECATED] Use New-CscuiProject.bat for new projects.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0New-CscuiProject.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
