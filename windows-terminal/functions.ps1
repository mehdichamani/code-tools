# eza aliases for PowerShell (Windows)
# Remove default ls alias
Remove-Item -Path Alias:ls -Force -ErrorAction SilentlyContinue
# Minimal listing with icons and Git status
function l { eza --icons=auto --git }
# Standard long listing with icons, Git status, and hyperlinks
function ls { eza --long --icons=auto --git --hyperlink }
# Detailed long listing with hidden files and relative dates
function ll { eza --long --icons=auto --git --hyperlink --all --time-style=relative }
# Short listing with all files (including hidden)
function la { eza --icons=auto --git --all }
# Tree view, 2 levels deep, with icons and Git status
function lt { eza --tree --level=2 --icons=auto --git }
# Long listing sorted by extension
function lx { eza --long --icons=auto --git --sort=extension }
# Long listing sorted by size (largest first)
function lsize { eza --long --icons=auto --git --sort=size --reverse }
# Long listing sorted by modification time (newest first)
function lnew { eza --long --icons=auto --git --sort=modified --reverse --time-style=relative }



# Clear shortcut
function c {
    Clear-Host
}

# Exit shortcut
function q {
    Exit
}

# Start my ffmpeg script here
function ffm {
    py "$HOME\OneDrive\code-tools\ffmpeg_script.py" @args
}

# Internal & External IP display
function myip {
    Write-Host "`n📡 Internal IPs:" -ForegroundColor Cyan
    Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -notlike '169.*' } | ForEach-Object {
        Write-Host "🔌 $($_.InterfaceAlias) ➜ $($_.IPAddress)"
    }
    Write-Host "`n🌍 External IP Info:" -ForegroundColor Cyan
    try {
        $info = Invoke-RestMethod -Uri "http://ip-api.com/json/" -TimeoutSec 10
        Write-Host "🌐 IP: $($info.query)"
        Write-Host "🏳️ Country: $($info.country) ($($info.countryCode))"
        Write-Host "🏙️ City: $($info.city)"
        Write-Host "🛰️ ISP: $($info.isp)"
    } catch {
        Write-Host "❌ Failed to retrieve external IP info." -ForegroundColor Red
    }
}

# change metrics of all network adapters
function metric {
    Write-Host "`n🔧 Interfaces found:" -ForegroundColor Cyan

    # Get interfaces and store them in an array to avoid pipeline binding issues
    $interfaces = @(Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" })

    # Display current metrics
    $interfaces | Sort-Object InterfaceMetric | Format-Table ifIndex, InterfaceAlias, InterfaceMetric

    foreach ($interface in $interfaces) {
        $name = $interface.InterfaceAlias
        $current = $interface.InterfaceMetric

        # Prompt user for new metric
        $input = Read-Host ">> Enter new metric for `"$name`" (Current: $current) [Enter to skip]"

        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Host "⏭️ Skipping $name (no change)" -ForegroundColor Yellow
            continue
        }

        if ($input -match '^\d+$') {
            try {
                Set-NetIPInterface -InterfaceAlias $name -InterfaceMetric $input -ErrorAction Stop
                Write-Host "✅ Metric of $name changed from $current to $input" -ForegroundColor Green
            } catch {
                Write-Host "❌ Error setting metric for ${name}: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "⚠️ Invalid input. Skipping $name..." -ForegroundColor Red
        }
    }

    Write-Host "`n📊 Final interface metrics:" -ForegroundColor Cyan
    Get-NetIPInterface -AddressFamily IPv4 | Sort-Object InterfaceMetric | Format-Table ifIndex, InterfaceAlias, InterfaceMetric
}


# Force shutdown with Enter confirmation
function shutdownnow {
    Write-Host "`n⚠️ Are you sure you want to force shutdown this PC?"
    Write-Host "Press Enter to confirm, Ctrl+C to cancel..."
    Read-Host
    Stop-Computer -Force
    Exit
}

# Run MKV organizer script
function mkv {
    py "$HOME\OneDrive\code-tools\mkvOrganizer.py"
}

# Toggle between Light and Dark theme
function ldtoggle {
    Write-Host "`n🎨 Checking current system theme..."
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    try {
        $currentTheme = (Get-ItemProperty -Path $regPath -Name SystemUsesLightTheme).SystemUsesLightTheme
    } catch {
        Write-Host "❌ Unable to read theme setting." -ForegroundColor Red
        return
    }
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    # Read the JSON
    $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if ($currentTheme -eq 0) {
        Write-Host "Current Theme: Dark ⚫"
        Write-Host "Press Enter to switch to Light Mode, Ctrl+C to cancel..."
        Read-Host
        Set-ItemProperty -Path $regPath -Name AppsUseLightTheme -Value 1
        Set-ItemProperty -Path $regPath -Name SystemUsesLightTheme -Value 1
        Write-Host "✅ Windows Color set to Light ⚪"
        $json.profiles.defaults.colorScheme = "One Half Light"
        Write-Host "✅ Terminal Color set to Light ⚪"                
    } else {
        Write-Host "Current Theme: Light ⚪"
        Write-Host "Press Enter to switch to Dark Mode, Ctrl+C to cancel..."
        Read-Host
        Set-ItemProperty -Path $regPath -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path $regPath -Name SystemUsesLightTheme -Value 0
        Write-Host "✅ Windows Color set to Dark ⚫"
        $json.profiles.defaults.colorScheme = "Campbell Powershell"
        Write-Host "✅ Terminal Color set to Dark ⚫"  
    }
    $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    Write-Host "✅ Terminal Color applied!" -ForegroundColor Green
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Host "✅ Windows Color applied!"    
    Write-Host "🎉 Done!"
}

# Moves all files from subfolders to the current directory root
function sub2root {
    Write-Host "`n📁 Moving files from subfolders to root of: $($PWD.Path)" -ForegroundColor Cyan
    Write-Host "Press Enter to start, Ctrl+C to cancel..."
    Read-Host

    $filesMoved = 0
    Get-ChildItem -Recurse -File | Where-Object { $_.DirectoryName -ne $PWD.Path } | ForEach-Object {
        $destination = Join-Path $PWD.Path $_.Name
        if (-not (Test-Path $destination)) {
            Write-Host "📦 Moving: $($_.FullName)"
            Move-Item $_.FullName $PWD.Path
            $filesMoved++
        } else {
            Write-Host "⚠️ Skipped (already exists): $($_.Name)" -ForegroundColor Yellow
        }
    }

    Write-Host "`n✅ Move completed! $filesMoved file(s) moved." -ForegroundColor Green

    Write-Host "`n🧹 Remove all empty folders?"
    Write-Host "Press Enter to confirm, Ctrl+C to cancel..."
    Read-Host

    $emptyFolders = Get-ChildItem -Directory -Recurse | Where-Object { (Get-ChildItem $_.FullName).Count -eq 0 }
    if ($emptyFolders.Count -gt 0) {
        $emptyFolders | Remove-Item
        Write-Host "🗑️ Empty folders removed!" -ForegroundColor Green
    } else {
        Write-Host "📂 No empty folders found." -ForegroundColor Gray
    }
}

# Microsoft Activation Scripts (MAS) online loader
function activescript {
    Write-Host "`n⚠️ This will execute a remote script from get.activated.win"
    Write-Host "Press Enter to proceed, Ctrl+C to cancel..."
    Read-Host

    try {
        irm https://get.activated.win | iex
        Write-Host "✅ Script executed successfully." -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to execute the script: $_" -ForegroundColor Red
    }
}

#lock open drive
function DriveLocker {
    # Check for admin rights
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "This script requires administrative privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }

    # Get all volumes
    $allVolumes = Get-BitLockerVolume

    # Filter volumes where BitLocker is enabled and mounted
    $enabledVolumes = $allVolumes | Where-Object {
        $_.KeyProtector.Count -gt 0 -and $_.MountPoint
    }

    if (-not $enabledVolumes) {
        Write-Host "No BitLocker-enabled volumes found." -ForegroundColor Yellow
        return
    }

    # Display volumes with drive letter and lock status
    Write-Host "`nBitLocker-Enabled Volumes:"
    $enabledVolumes | ForEach-Object {
        $status = if ($_.VolumeStatus -eq $null) {
            '🔒 Locked'
        } elseif ($_.VolumeStatus -eq 'FullyEncrypted') {
            '🔓 Unlocked'
        } else {
            '❌ Not Encrypted'
        }
        Write-Host "Drive Letter: $($_.MountPoint) | Status: $status"
    }

    # Ask user to enter drive letter to lock (allow with or without colon and backslash)
    $inputDrive = Read-Host "`nEnter the drive letter you want to lock (e.g., D or D:)"

    # Normalize input to drive letter with trailing colon (e.g. "D:")
    $normalizedDrive = $inputDrive.Trim().ToUpper().TrimEnd('\')
    if ($normalizedDrive.Length -eq 1) {
        $normalizedDrive += ":"
    }

    # Validate if the drive is in the enabledVolumes list and unlocked
    $selectedVolume = $enabledVolumes | Where-Object { $_.MountPoint.TrimEnd('\').ToUpper() -eq $normalizedDrive }

    if (-not $selectedVolume) {
        Write-Host "Drive letter '$normalizedDrive' is not a valid BitLocker-enabled volume or not unlocked." -ForegroundColor Red
        return
    }

    # Lock the selected volume
    Write-Host "`nLocking drive $normalizedDrive..."
    $lockResult = manage-bde -lock $normalizedDrive

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Drive $normalizedDrive locked successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to lock drive $normalizedDrive." -ForegroundColor Red
    }

    Write-Host "`nDone."
}

# windows registry tweaks
function regTools {
    # Ensure the script runs in a suitable host for registry work
    Write-Host ""
    Write-Host "=== Registry Tools ===" -ForegroundColor Cyan
    Write-Host "Select a tweak to apply:"
    $menu = @(
        @{
            Index = 1
            Name  = "Add 'Run in Terminal' context menu for .ps1 and .bat"
            Desc  = "Adds right-click entries to open scripts in Windows Terminal with PowerShell 7 Preview and Command Prompt."
        },
        @{
            Index = 2
            Name  = "Shortcut suffix remover"
            Desc  = "Removes the ' - Shortcut' suffix by setting ShortcutNameTemplate to %s.lnk for new shortcuts."
        }
    )

    foreach ($item in $menu) {
        Write-Host ("[{0}] {1}" -f $item.Index, $item.Name) -ForegroundColor Yellow
        Write-Host ("     {0}" -f $item.Desc) -ForegroundColor DarkGray
    }

    $choice = Read-Host "`nEnter the number of the tweak to apply (or press Enter to cancel)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Host "Canceled."
        return
    }

    if (-not ($choice -match '^\d+$')) {
        Write-Host "Invalid choice." -ForegroundColor Red
        return
    }

    $choice = [int]$choice

    # Helper: check admin
    function _Require-Admin {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "This action requires administrative privileges. Please run PowerShell as Administrator." -ForegroundColor Red
            return $false
        }
        return $true
    }

    switch ($choice) {
        1 {
            # Add 'Run in Terminal' context menu for .ps1 and .bat
            Write-Host "`nYou chose: Add 'Run in Terminal' context menu for .ps1 and .bat"
            Write-Host "This will write under HKCR\SystemFileAssociations for .ps1 and .bat."
            if (-not (_Require-Admin)) { return }

            try {
                # .ps1
                New-Item -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell" -Force | Out-Null
                Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell" -Name '(default)' -Value 'powershell'

                New-Item -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunAs" -Force | Out-Null
                Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunAs" -Name '(default)' -Value 'Run in Terminal'

                New-Item -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunAs\Command" -Force | Out-Null
                Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\RunAs\Command" -Name '(default)' -Value 'wt.exe -w 0 nt -p "PowerShell 7 Preview" pwsh.exe -NoExit -File "%1"'

                # .bat
                New-Item -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bat\Shell" -Force | Out-Null
                Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bat\Shell" -Name '(default)' -Value 'open'

                New-Item -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bat\Shell\RunInTerminal" -Force | Out-Null
                Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bat\Shell\RunInTerminal" -Name '(default)' -Value 'Run in Terminal'

                New-Item -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bat\Shell\RunInTerminal\Command" -Force | Out-Null
                Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bat\Shell\RunInTerminal\Command" -Name '(default)' -Value 'wt.exe -w 0 nt -p "Command Prompt" cmd.exe /k "%1"'


                Write-Host "✅ Context menu entries created/updated successfully." -ForegroundColor Green
                Write-Host "Note: Ensure Windows Terminal profiles 'PowerShell 7 Preview' and 'Command Prompt' exist."
            } catch {
                Write-Host "❌ Failed to apply context menu entries: $_" -ForegroundColor Red
            }
        }
        2 {
            # Shortcut suffix remover (HKCU NamingTemplates)
            Write-Host "`nYou chose: Shortcut suffix remover"
            Write-Host "This sets HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates\ShortcutNameTemplate = %s.lnk"
            try {
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates"
                $valueName = "ShortcutNameTemplate"
                $valueData = "%s.lnk"

                New-Item -Path $regPath -Force | Out-Null
                New-ItemProperty -Path $regPath -Name $valueName -Value $valueData -PropertyType String -Force | Out-Null

                Write-Host "✅ Shortcut naming template updated successfully!" -ForegroundColor Green
                Write-Host "New shortcuts should no longer append the ' - Shortcut' suffix."
                Write-Host "An Explorer restart may be needed for consistency."
            } catch {
                Write-Host "❌ Failed to update the shortcut naming template: $_" -ForegroundColor Red
            }
        }
        Default {
            Write-Host "Unknown selection." -ForegroundColor Red
        }
    }

    Write-Host ""
    Read-Host -Prompt "Press Enter to continue"
}
