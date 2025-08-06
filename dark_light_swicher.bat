@echo off
echo Checking current system theme...

REM Read the SystemUsesLightTheme value from the registry
for /f "tokens=3" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme 2^>nul') do set currentTheme=%%A

REM Check the current theme value
if "%currentTheme%"=="0x0" (
    echo Current Theme: Dark Mode
    echo Switching to Light Mode...
    powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value 1"
    powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme -Value 1"
    echo Switched to Light Mode!
) else (
    echo Current Theme: Light Mode
    echo Switching to Dark Mode...
    powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value 0"
    powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme -Value 0"
    echo Switched to Dark Mode!
)

REM Restart Windows Explorer to apply the theme change
echo Restarting Windows Explorer...
taskkill /f /im explorer.exe >nul
start explorer.exe

echo Done!
pause
