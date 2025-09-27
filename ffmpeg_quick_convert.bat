@echo off
setlocal enabledelayedexpansion

echo This script will copy all files in this folder to "output" folder using ffmpeg -c copy.
echo Press Enter to start or Ctrl+C to abort.
pause >nul

rem Create output folder if it does not exist
if not exist "output" mkdir "output"

rem For each file in current folder (except folders)
for %%f in (*) do (
    rem Skip this batch file itself
    if not "%%~nxf"=="%~nx0" (
        echo Copying %%f ...
        ffmpeg -i "%%f" -c copy "output\%%f"
    )
)

echo Done.
pause
