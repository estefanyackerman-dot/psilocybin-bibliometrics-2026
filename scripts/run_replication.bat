@echo off
REM Runs the bibliometrix replication with Rscript directly, so no PowerShell
REM script execution (and no Set-ExecutionPolicy change) is needed.
setlocal
set "SCRIPT_DIR=%~dp0"

where Rscript >nul 2>nul
if errorlevel 1 (
    echo Rscript was not found on PATH. Install R and ensure Rscript.exe is on PATH.
    exit /b 1
)

Rscript "%SCRIPT_DIR%02_bibliometrix_replication.R" %*
endlocal
