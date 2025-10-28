<#
.SYNOPSIS
    Links PowerShell, Windows Terminal, and Starship configuration files
    from a central OneDrive folder.

.DESCRIPTION
    This script creates symbolic links for:
    1. PowerShell Profile
    2. Windows Terminal settings.json
    3. Starship starship.toml

    It automatically backs up any existing files (e.g., "Profile.ps1.bak")
    before creating the links. It is safe to run multiple times.

.NOTES
    This script does NOT require Administrator rights, as all links
    are created within your user profile directory ($HOME).
#>

# --- 1. DEFINE YOUR PATHS ---
Write-Host "Setting up configuration paths..." -ForegroundColor Cyan

# Source folder in your OneDrive
$OneDriveBase = "$HOME\OneDrive\code-tools\windows-terminal"

# Source files (the "real" files in OneDrive)
$Source_Profile = "$OneDriveBase\Profile.ps1"
$Source_WT_Settings = "$OneDriveBase\settings.json"
$Source_Starship = "$OneDriveBase\starship.toml"

# Target paths (where the symlinks will be created)
$Target_Profile = $PROFILE  # This is the built-in variable: $HOME\Documents\PowerShell\Profile.ps1
$Target_Starship = "$HOME\.config\starship.toml"

# Dynamically find the Windows Terminal settings path
$WT_Stable_Path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$WT_Preview_Path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
$Target_WT_Settings = $null

if (Test-Path (Split-Path $WT_Stable_Path -Parent)) {
    $Target_WT_Settings = $WT_Stable_Path
    Write-Host "Found Windows Terminal (Stable) settings path."
}
elseif (Test-Path (Split-Path $WT_Preview_Path -Parent)) {
    $Target_WT_Settings = $WT_Preview_Path
    Write-Host "Found Windows Terminal (Preview) settings path."
}
else {
    Write-Warning "Could not find a Windows Terminal settings path. Skipping."
}


# --- 2. UNBLOCK ONEDRIVE FILES ---
# Files from OneDrive are often "blocked" by Windows. This unblocks them.
Write-Host "Attempting to unblock source files (in case of OneDrive sync)..." -ForegroundColor Cyan
Unblock-File -Path $Source_Profile -ErrorAction SilentlyContinue
Unblock-File -Path $Source_WT_Settings -ErrorAction SilentlyContinue
Unblock-File -Path $Source_Starship -ErrorAction SilentlyContinue


# --- 3. CONFIRMATION PROMPT ---
Write-Host "`nThis script will link your config files from OneDrive." -ForegroundColor Yellow
Write-Host "It will back up any existing files it finds." -ForegroundColor Yellow
try {
    Read-Host "Press ENTER to continue, or CTRL+C to cancel"
}
catch {
    Write-Host "`nOperation cancelled by user." -ForegroundColor Red
    return # Exit the script
}


# --- 4. HELPER FUNCTION ---
function Create-SafeSymlink {
    param (
        [string]$Source,
        [string]$Target
    )

    # Check if the source file actually exists
    if (!(Test-Path $Source)) {
        Write-Warning "Source file not found, skipping: $Source"
        return
    }

    # Ensure the target directory exists (e.g., $HOME\.config)
    $TargetDir = Split-Path $Target -Parent
    if (!(Test-Path $TargetDir)) {
        Write-Host "Creating directory: $TargetDir"
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # Check if a file/link already exists at the target
    if (Test-Path $Target -PathType Leaf) {
        $item = Get-Item $Target
        if ($item.LinkType -eq 'SymbolicLink') {
            # It's already a link, just confirm it's correct
            if ($item.Target -eq $Source) {
                Write-Host "Correct link already exists: $Target" -ForegroundColor Gray
            } else {
                Write-Warning "Link exists but points to wrong target: $Target"
            }
        }
        else {
            # It's a real file, back it up
            $BackupPath = "$Target.bak"
            Write-Host "Backing up existing file to: $BackupPath" -ForegroundColor Yellow
            Move-Item -Path $Target -Destination $BackupPath -Force
            
            # Create the new link
            Write-Host "Creating symlink: $Target -> $Source" -ForegroundColor Green
            New-Item -ItemType SymbolicLink -Path $Target -Value $Source
        }
    }
    else {
        # Path is clear, create the link
        Write-Host "Creating symlink: $Target -> $Source" -ForegroundColor Green
        New-Item -ItemType SymbolicLink -Path $Target -Value $Source
    }
}


# --- 5. EXECUTE THE LINKING ---
Write-Host "`n--- Starting Linking Process ---"

# Link PowerShell Profile
Create-SafeSymlink -Source $Source_Profile -Target $Target_Profile

# Link Starship Config
Create-SafeSymlink -Source $Source_Starship -Target $Target_Starship

# Link Windows Terminal Settings (only if path was found)
if ($Target_WT_Settings) {
    Create-SafeSymlink -Source $Source_WT_Settings -Target $Target_WT_Settings
}
else {
    Write-Warning "Skipped Windows Terminal settings link (path not found)."
}

Write-Host "`n--- All tasks complete! ---" -ForegroundColor Green
Write-Host "Restart your PowerShell and Windows Terminal to see changes."