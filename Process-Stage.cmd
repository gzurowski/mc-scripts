@echo off
call %cd%\Config.cmd
powershell %cd%\Clean-Stage.ps1 %STAGE_DIR%
powershell %cd%\Process-Stage.ps1 %STAGE_DIR%
echo.
pause
