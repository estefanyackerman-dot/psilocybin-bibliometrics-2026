@echo off
REM Runs the bibliometrix replication with the project-local Rscript if present,
REM otherwise falls back to the standard Windows R install locations.
setlocal
set "SCRIPT_DIR=%~dp0"
set "RSCRIPT="

where Rscript >nul 2>nul
if not errorlevel 1 set "RSCRIPT=Rscript"

if not defined RSCRIPT (
    for /d %%D in ("%ProgramFiles%\R\R-*") do (
        if exist "%%~D\bin\Rscript.exe" (
            set "RSCRIPT=%%~D\bin\Rscript.exe"
            goto run_script
        )
    )
    for /d %%D in ("%ProgramFiles(x86)%\R\R-*") do (
        if exist "%%~D\bin\Rscript.exe" (
            set "RSCRIPT=%%~D\bin\Rscript.exe"
            goto run_script
        )
    )
    for /d %%D in ("%LOCALAPPDATA%\Programs\R\R-*") do (
        if exist "%%~D\bin\Rscript.exe" (
            set "RSCRIPT=%%~D\bin\Rscript.exe"
            goto run_script
        )
    )
)

:run_script
if not defined RSCRIPT (
    echo Rscript was not found on PATH or in the default Windows R install locations.
    echo Install R from https://cran.r-project.org/ and ensure Rscript.exe is available.
    exit /b 1
)

"%RSCRIPT%" "%SCRIPT_DIR%02_bibliometrix_replication.R" %*
endlocal
