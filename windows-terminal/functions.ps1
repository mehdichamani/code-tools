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


