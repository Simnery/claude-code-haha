@echo off
set "CALLER_DIR=%CD%"
cd /d "%~dp0"

set "PATH=%USERPROFILE%\.bun\bin;%PATH%"

where bun >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Bun not found. Install: https://bun.sh
    pause
    exit /b 1
)

if not exist ".env" (
    echo [ERROR] .env not found. Run: copy .env.example .env
    pause
    exit /b 1
)

findstr /r "^[^#]*your_" .env >nul 2>&1
if %errorlevel% equ 0 (
    echo [WARN] Placeholder "your_" in .env, edit it with real API Key.
    pause
    exit /b 1
)

echo Starting Claude Code Haha...
bun ./src/entrypoints/cli.tsx %*
