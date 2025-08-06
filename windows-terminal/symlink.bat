@echo off
net session >nul 2>&1
if errorlevel 1 (
    echo This script requires administrator privileges
    echo Please run as administrator
    pause
    exit /b 1
)

setlocal EnableDelayedExpansion

REM 📁 مسیر فولدر فعلی فایل bat
set "CURRENT_DIR=%~dp0"

REM ====================================
REM 🔗 Windows Terminal settings.json symlink
REM ====================================
set "WT_LINK=%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
set "WT_TARGET=%CURRENT_DIR%settings.json"

if not exist "%WT_TARGET%" (
    echo Windows Terminal settings file not found: %WT_TARGET%
    pause
    exit /b 1
)

if exist "%WT_LINK%" (
    del "%WT_LINK%"
)

echo Creating Windows Terminal settings symlink...
mklink "%WT_LINK%" "%WT_TARGET%"
if errorlevel 1 (
    echo Failed to create Windows Terminal settings symlink
    pause
    exit /b 1
)


REM ====================================
REM 🔗 PowerShell profile symlink
REM ====================================
REM Get Documents path from registry
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Personal ^| find "Personal"') do (
    set "DOCS=%%b"
)

REM PowerShell profile path
set "PWSH_FOLDER=%DOCS%\PowerShell"
set "PWSH_LINK=%PWSH_FOLDER%\Microsoft.PowerShell_profile.ps1"
set "PWSH_TARGET=%CURRENT_DIR%Microsoft.PowerShell_profile.ps1"

if not exist "%PWSH_TARGET%" (
    echo PowerShell profile file not found: %PWSH_TARGET%
    pause
    exit /b 1
)

REM Create PowerShell folder if it doesn't exist
if not exist "%PWSH_FOLDER%" (
    mkdir "%PWSH_FOLDER%"
    if errorlevel 1 (
        echo Failed to create PowerShell folder
        pause
        exit /b 1
    )
)

REM Remove existing file
if exist "%PWSH_LINK%" (
    del "%PWSH_LINK%"
)

echo Creating PowerShell profile symlink...
mklink "%PWSH_LINK%" "%PWSH_TARGET%"
if errorlevel 1 (
    echo Failed to create PowerShell profile symlink
    pause
    exit /b 1
)

echo.
echo Symlinks created successfully!
echo Windows Terminal settings: %WT_LINK%
echo PowerShell profile: %PWSH_LINK%
pause
