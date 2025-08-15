function Get-MyIPInfo {
    Write-Host "`n📡 Internal IPs:"
    Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'} | ForEach-Object {
        Write-Host "🔌 $($_.InterfaceAlias) ➜ $($_.IPAddress)"
    }

    Write-Host "`n🌍 External IP Info:"
    $info = Invoke-RestMethod -Uri "http://ip-api.com/json/" -TimeoutSec 10
    
    Write-Host "🌐 IP: $($info.query)
    🏳️ Country: $($info.country) ($($info.countryCode))
    🏙️ City: $($info.city)
    🛰️ ISP: $($info.isp)"
}
Set-Alias -Name myip -Value Get-MyIPInfo
#######################################################

function Set-MyNetworkMetric {
    Write-Host "Interfaces found:" -ForegroundColor Cyan
    $interfaces = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" }
    $interfaces | Sort-Object InterfaceMetric | Format-Table ifIndex, InterfaceAlias, InterfaceMetric

    foreach ($interface in $interfaces) {
        $interfaceName = $interface.InterfaceAlias
        $currentMetric = $interface.InterfaceMetric
        
        $metric = Read-Host ">> Enter new metric for `"$interfaceName`" (Current: $currentMetric) [Press Enter to skip]"
        
        if ($metric -eq "") {
            Write-Host "Skipping $interfaceName (no change)" -ForegroundColor Yellow
            continue
        }
        elseif ($metric -match '^\d+$') {
            try {
                Set-NetIPInterface -InterfaceAlias $interfaceName -InterfaceMetric $metric -ErrorAction Stop
                Write-Host "Metric of $interfaceName changed from $currentMetric to $metric" -ForegroundColor Green
            }
            catch {
                Write-Host "Error setting metric for ${interfaceName}: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Invalid input. Skipping ${interfaceName}..." -ForegroundColor Red
        }
    }

    Write-Host "`nFinal interface metrics:" -ForegroundColor Cyan
    Get-NetIPInterface -AddressFamily IPv4 | Sort-Object InterfaceMetric | Format-Table ifIndex, InterfaceAlias, InterfaceMetric
}
Set-Alias -Name metric -Value Set-MyNetworkMetric
#######################################################
function Stop-MyComputer {
    stop-computer -force
    exit
}
Set-Alias -Name off -Value Stop-MyComputer
#######################################################
function Start-MkvOrganizer {
    python "C:\Users\Mehdi\OneDrive\code-tools\mkvOrganizer.py"
}
Set-Alias -Name mkv -Value Start-MkvOrganizer
#######################################################
function Toggle-SystemTheme {
    Write-Host "Checking current system theme..."

    $currentTheme = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme).SystemUsesLightTheme

    if ($currentTheme -eq 0) {
        Write-Host "Current Theme: Dark Mode"
        Write-Host "Switching to Light Mode..."
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value 1
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme -Value 1
        Write-Host "Switched to Light Mode!"
    } else {
        Write-Host "Current Theme: Light Mode"
        Write-Host "Switching to Dark Mode..."
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme -Value 0
        Write-Host "Switched to Dark Mode!"
    }

    Write-Host "Restarting Windows Explorer..."
    Stop-Process -Name explorer -Force
    Start-Process explorer

    Write-Host "Done!"
}
Set-Alias -Name ldtoggle -Value Toggle-SystemTheme
#######################################################
Set-Alias -Name c -Value Clear-Host
#######################################################
function Exit-Terminal {
    Exit
}
Set-Alias -Name q -Value Exit-Terminal
