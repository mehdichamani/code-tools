# File: ssh-termux.ps1

# آی‌پی پیش‌فرض
$defaultIP = "192.168.1.50"

# دریافت IP از کاربر
$ip = Read-Host "Enter IP address (default: $defaultIP)"
if ([string]::IsNullOrWhiteSpace($ip)) {
    $ip = $defaultIP
}

# اجرای دستور SSH
ssh -i "~/.ssh/id_multiusekey" -p 8022 u0_a355@$ip

# مکث برای بستن پنجره
pause
