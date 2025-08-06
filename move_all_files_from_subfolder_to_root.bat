@echo off
setlocal enabledelayedexpansion

echo Moving files from subfolders to main folder...
for /r "%CD%" %%F in (*) do (
    if not exist "%CD%\%%~nxF" (
        echo Moving: %%F
        move "%%F" "%CD%"
    )
)

echo.
echo Move completed!
pause

setlocal enabledelayedexpansion