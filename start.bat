@echo off
setlocal enabledelayedexpansion
title Marina Trading IMS - server

REM ===========================================================================
REM  Starts the Inventory Monitoring System and makes it reachable from every
REM  other machine on the office network.
REM
REM  First run: creates the virtual environment and installs the dependencies.
REM  Optional argument: a port number (default 8080).
REM ===========================================================================

cd /d "%~dp0backend"

set "PORT=8080"
if not "%~1"=="" set "PORT=%~1"

REM --- find Python -----------------------------------------------------------
set "PY="
for %%C in (py python) do if not defined PY (
  %%C --version >nul 2>&1 && set "PY=%%C"
)
if not defined PY (
  echo [ERROR] Python was not found on this machine.
  echo         Install Python 3.10 or newer from https://python.org and tick
  echo         "Add python.exe to PATH" during setup.
  pause & exit /b 1
)

REM --- virtual environment ---------------------------------------------------
if not exist ".venv\Scripts\python.exe" (
  echo Creating the virtual environment ^(first run only^)...
  %PY% -m venv .venv || (echo [ERROR] Could not create .venv & pause & exit /b 1)
  ".venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
  echo Installing dependencies...
  ".venv\Scripts\python.exe" -m pip install -r requirements.txt --quiet || (
    echo [ERROR] Dependency installation failed & pause & exit /b 1
  )
)

REM --- database --------------------------------------------------------------
if not exist "..\database\ims.sqlite" (
  echo.
  echo  No database found at database\ims.sqlite
  echo.
  echo  Load the legacy data first:
  echo      backend\.venv\Scripts\python.exe backend\migrate.py
  echo.
  echo  Starting anyway with an empty database - an ADMIN account will be
  echo  created with the password 'changeme'.
  echo.
)

set "IMS_PORT=%PORT%"
set "IMS_HOST=0.0.0.0"

echo.
echo  Starting on port %PORT%. Close this window to stop the server.
echo  Other PCs use the "Network" address printed below.
echo.

".venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port %PORT%

echo.
echo  The server has stopped.
pause
endlocal
