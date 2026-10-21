@echo off

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    ECHO This script requires administrative privileges.
    ECHO Please right-click this file and select "Run as administrator".
    ECHO Press any key to exit . . .
    pause >nul
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %ERRORLEVEL% neq 0 (
    ECHO Failure. Check the error messages above.
    ECHO Press any key to exit . . .
    pause >nul
    exit /b 1
)

ECHO Press any key to exit . . .
pause >nul
exit /b 0