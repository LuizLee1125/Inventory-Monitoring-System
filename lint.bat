@echo off
setlocal enabledelayedexpansion
title Marina Trading IMS - lint

REM ===========================================================================
REM  Lints both halves of the project and returns a single pass/fail.
REM
REM    lint.bat          check only
REM    lint.bat --fix    apply the fixes that can be applied automatically
REM ===========================================================================

cd /d "%~dp0"

set "FIXMODE="
if /i "%~1"=="--fix" set "FIXMODE=1"

set "RUFF_ARGS=check backend"
set "ESLINT_ARGS=frontend/**/*.js desktop/ui/**/*.js"
if defined FIXMODE (
  set "RUFF_ARGS=check backend --fix"
  set "ESLINT_ARGS=frontend/**/*.js desktop/ui/**/*.js --fix"
)

set "FAILED="

REM --- backend ---------------------------------------------------------------
echo.
echo ==== backend (ruff) =======================================================
if not exist "backend\.venv\Scripts\python.exe" (
  echo [SKIP] No virtual environment. Run start.bat once, then:
  echo        backend\.venv\Scripts\python.exe -m pip install -r backend\requirements-dev.txt
  set "FAILED=1"
) else (
  "backend\.venv\Scripts\python.exe" -m ruff --version >nul 2>&1
  if errorlevel 1 (
    echo Installing ruff ^(first run only^)...
    "backend\.venv\Scripts\python.exe" -m pip install -q -r backend\requirements-dev.txt
  )
  "backend\.venv\Scripts\python.exe" -m ruff %RUFF_ARGS%
  if errorlevel 1 set "FAILED=1"
)

REM --- frontend --------------------------------------------------------------
echo.
echo ==== frontend (eslint) ====================================================
where npm >nul 2>&1
if errorlevel 1 (
  echo [SKIP] Node.js is not installed, so the frontend cannot be linted.
  echo        Install it from https://nodejs.org - it is only needed for linting,
  echo        never to run the application.
) else (
  if not exist "node_modules\eslint" (
    echo Installing eslint ^(first run only^)...
    call npm install --silent --no-fund --no-audit
  )
  call npx --no-install eslint %ESLINT_ARGS%
  if errorlevel 1 set "FAILED=1"
)

REM --- verdict ---------------------------------------------------------------
echo.
if defined FAILED (
  echo ==== FAILED ===============================================================
  if not defined FIXMODE echo Try: lint.bat --fix
  exit /b 1
) else (
  echo ==== CLEAN ================================================================
  exit /b 0
)
