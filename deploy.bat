@echo off
setlocal enabledelayedexpansion

REM =================================================================
REM Sora Video Generator - Windows Batch Deployment Launcher
REM =================================================================
REM This batch file provides a Windows-native way to launch the
REM PowerShell deployment script with proper error handling.
REM =================================================================

echo.
echo ===============================================================
echo    SORA VIDEO GENERATOR - DEPLOYMENT LAUNCHER
echo ===============================================================
echo.

REM Check if PowerShell 7+ is available (preferred)
where pwsh.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "POWERSHELL_EXE=pwsh.exe"
    echo Using PowerShell 7+ ^(pwsh.exe^)
) else (
    REM Fallback to Windows PowerShell 5.1
    where powershell.exe >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Neither PowerShell 7+ ^(pwsh.exe^) nor Windows PowerShell ^(powershell.exe^) found.
        echo Please install PowerShell 7+ from: https://github.com/PowerShell/PowerShell/releases
        echo.
        pause
        exit /b 1
    )
    set "POWERSHELL_EXE=powershell.exe"
    echo Using Windows PowerShell 5.1 ^(powershell.exe^)
    echo WARNING: PowerShell 7+ is recommended for optimal compatibility.
)

REM Check if the PowerShell deployment script exists
set "SCRIPT_PATH=%~dp0deploy.ps1"
if not exist "%SCRIPT_PATH%" (
    echo ERROR: PowerShell deployment script not found at:
    echo %SCRIPT_PATH%
    echo.
    echo Please ensure the deploy.ps1 file exists in the same directory.
    echo.
    pause
    exit /b 1
)

echo Starting PowerShell deployment script...
echo Script location: %SCRIPT_PATH%
echo PowerShell version: !POWERSHELL_EXE!
echo.

REM Execute PowerShell script with proper error handling
!POWERSHELL_EXE! -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_PATH%"
set "PS_EXIT_CODE=!ERRORLEVEL!"

echo.
echo ===============================================================

REM Check PowerShell execution result
if !PS_EXIT_CODE! equ 0 (
    echo ✅ PowerShell deployment script completed successfully!
) else (
    echo ❌ PowerShell deployment script failed with exit code: !PS_EXIT_CODE!
    echo.
    echo Common solutions:
    echo - Check the PowerShell execution policy
    echo - Ensure you have administrator privileges
    echo - Review the deployment log for detailed error information
)

echo.
echo Press any key to close this window...
pause >nul

REM Exit with the same code as PowerShell script
exit /b !PS_EXIT_CODE!
