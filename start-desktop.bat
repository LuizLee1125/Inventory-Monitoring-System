@echo off
setlocal
title Marina Trading IMS - desktop app (development)

REM ===========================================================================
REM  Runs the desktop edition from source.
REM
REM  This is the development launcher, the counterpart of start.bat. For the
REM  office, build an installer instead:  cd desktop  &&  npm run build
REM
REM  Needs Node.js and the Rust toolchain; see desktop\README.md.
REM ===========================================================================

cd /d "%~dp0desktop"

where node >nul 2>&1 || (
  echo [ERROR] Node.js was not found. Install it from https://nodejs.org
  pause & exit /b 1
)
where cargo >nul 2>&1 || (
  echo [ERROR] The Rust toolchain was not found. Install it from https://rustup.rs
  pause & exit /b 1
)

if not exist "node_modules" (
  echo Installing the Tauri CLI ^(first run only^)...
  call npm install || (echo [ERROR] npm install failed & pause & exit /b 1)
)

if not exist "src-tauri\icons\icon.ico" (
  echo Generating the application icons ^(first run only^)...
  call npm run icon || (echo [ERROR] icon generation failed & pause & exit /b 1)
)

echo.
echo  Building and starting the desktop app. The first build compiles the whole
echo  Rust toolchain's worth of dependencies and takes several minutes; later
echo  ones are quick.
echo.

call npm run dev

endlocal
