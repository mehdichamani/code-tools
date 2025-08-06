# دریافت لیست تمام اینترفیس‌های IPv4
$interfaces = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" }

Write-Host "Interfaces found:" -ForegroundColor Cyan
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

# نمایش نتیجه نهایی
Write-Host "`nFinal interface metrics:" -ForegroundColor Cyan
Get-NetIPInterface -AddressFamily IPv4 | Sort-Object InterfaceMetric | Format-Table ifIndex, InterfaceAlias, InterfaceMetric