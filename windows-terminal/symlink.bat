@echo off
net session >nul 2>&1
if errorlevel 1 (
    echo This script requires administrator privileges
    echo Please run as administrator
    pause
    exit /b 1
)

setlocal EnableDelayedExpansion

set "CURRENT_DIR=%~dp0"
set "SUCCESS_COUNT=0"
set "FAIL_COUNT=0"

REM Get Documents path for PowerShell profile
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Personal ^| find "Personal"') do (
    set "DOCS=%%b"
)

REM ====================================
REM 📋 SYMLINK CONFIGURATION
REM ====================================

REM Windows Terminal Settings
set "NAME[0]=Windows Terminal Settings"
set "LINK[0]=%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
set "TARGET[0]=%CURRENT_DIR%settings.json"
set "FOLDER[0]="

REM PowerShell Profile
set "NAME[1]=PowerShell Profile"
set "LINK[1]=%UserProfile%Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
set "TARGET[1]=%CURRENT_DIR%Microsoft.PowerShell_profile.ps1"
set "FOLDER[1]=%UserProfile%Documents\PowerShell"

REM Add more symlinks here:
set "NAME[2]=starship"
set "LINK[2]=%UserProfile%\.config\starship.toml"
set "TARGET[2]=%CURRENT_DIR%starship.toml"
set "FOLDER[2]=%UserProfile%\.config"

echo Creating symlinks...
echo.

for /L %%i in (0,1,2) do (
    if defined NAME[%%i] (
        call :ProcessSymlink %%i
    )
)

echo.
echo ====================================
echo Summary: %SUCCESS_COUNT% successful, %FAIL_COUNT% failed
echo ====================================
pause
exit /b 0

:ProcessSymlink
set "IDX=%1"
set "NAME=!NAME[%IDX%]!"
set "LINK=!LINK[%IDX%]!"
set "TARGET=!TARGET[%IDX%]!"
set "FOLDER=!FOLDER[%IDX%]!"

echo [%NAME%]
if not exist "%TARGET%" (
    echo   FAIL - Target file not found: %TARGET%
    set /a FAIL_COUNT+=1
    goto :eof
)

if not "%FOLDER%"=="" (
    if not exist "%FOLDER%" (
        mkdir "%FOLDER%" 2>nul
        if errorlevel 1 (
            echo   FAIL - Could not create folder: %FOLDER%
            set /a FAIL_COUNT+=1
            goto :eof
        )
    )
)

if exist "%LINK%" del "%LINK%" 2>nul
mklink "%LINK%" "%TARGET%" >nul 2>&1
if errorlevel 1 (
    echo   FAIL - Could not create symlink
    set /a FAIL_COUNT+=1
) else (
    echo   DONE - %LINK%
    set /a SUCCESS_COUNT+=1
)
goto :eof
