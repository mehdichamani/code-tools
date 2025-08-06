echo Changing Shortcut Naming Template...
REM Check if the registry key already exists
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates" /v ShortcutNameTemplate >nul 2>&1
if %errorlevel% equ 0 (
    echo Shortcut naming template already exists. Overwriting...
) else (
    echo Creating new shortcut naming template...
)

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates" /v ShortcutNameTemplate /t REG_SZ /d "%%s.lnk" /f
if %errorlevel% equ 0 (
    echo Shortcut naming template updated successfully!
) else (
    echo Failed to update the shortcut naming template.
)
pause