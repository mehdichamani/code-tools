# Aliases
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name ffm -Value "py ~\OneDrive\code-tools\ffmpeg_script.py"
Set-Alias -Name ffc -Value "py ~\OneDrive\code-tools\ffmpeg_script.py"

# Exit shortcut
function q {
    Exit
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
    python "C:\Users\Mehdi\OneDrive\code-tools\mkvOrganizer.py"
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

    if ($currentTheme -eq 0) {
        Write-Host "🌑 Current Theme: Dark Mode"
        Write-Host "Press Enter to switch to Light Mode, Ctrl+C to cancel..."
        Read-Host
        Set-ItemProperty -Path $regPath -Name AppsUseLightTheme -Value 1
        Set-ItemProperty -Path $regPath -Name SystemUsesLightTheme -Value 1
        Write-Host "✅ Switched to Light Mode!"
    } else {
        Write-Host "🌕 Current Theme: Light Mode"
        Write-Host "Press Enter to switch to Dark Mode, Ctrl+C to cancel..."
        Read-Host
        Set-ItemProperty -Path $regPath -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path $regPath -Name SystemUsesLightTheme -Value 0
        Write-Host "✅ Switched to Dark Mode!"
    }

    Write-Host "🔄 Restarting Windows Explorer..."
    Stop-Process -Name explorer -Force
    Start-Process explorer
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
