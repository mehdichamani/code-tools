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

Set-Alias -Name setmetric -Value Set-MyNetworkMetric
Set-Alias -Name myip -Value Get-MyIPInfo


