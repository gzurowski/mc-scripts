@echo off
call %cd%\Config.cmd
powershell %cd%\Test-FlacFiles.ps1 %STAGE_DIR%
echo.
pause
