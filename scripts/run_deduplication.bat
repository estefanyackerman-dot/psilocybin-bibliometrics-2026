@echo off
REM Runs the deduplication pipeline using the project's .venv directly, so no
REM PowerShell script execution (and no Set-ExecutionPolicy change) is needed.
setlocal
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
set "VENV_PY=%REPO_ROOT%\.venv\Scripts\python.exe"

if exist "%VENV_PY%" (
    "%VENV_PY%" "%SCRIPT_DIR%01_deduplication_pipeline.py" %*
) else (
    python "%SCRIPT_DIR%01_deduplication_pipeline.py" %*
)
endlocal
