# cast-http.ps1
$ip   = "192.168.1.100"
$port = 8090

Write-Host "======================================="
Write-Host " 📡 Desktop Stream via FFmpeg (HTTP)"
Write-Host "======================================="
Write-Host " Local IP   : $ip"
Write-Host " Port       : $port"
Write-Host ""
Write-Host " ▶ On VLC (phone/laptop/TV) open:"
Write-Host "    http://$ip`:$port"
Write-Host "======================================="

# Run ffmpeg
ffmpeg -f gdigrab -i desktop -framerate 30 `
-c:v libx264 -preset ultrafast -tune zerolatency `
-f mpegts -listen 1 http://$ip`:$port
