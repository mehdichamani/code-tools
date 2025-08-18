# cast-rtsp.ps1
$ip   = "192.168.1.100"
$port = 8554

Write-Host "======================================="
Write-Host " 📡 Desktop Stream via FFmpeg (RTSP)"
Write-Host "======================================="
Write-Host " Local IP   : $ip"
Write-Host " Port       : $port"
Write-Host ""
Write-Host " ▶ On VLC (phone/laptop/TV) open:"
Write-Host "    rtsp://$ip`:$port/live.sdp"
Write-Host "======================================="

# Run ffmpeg
ffmpeg -f gdigrab -i desktop -framerate 30 `
-c:v libx264 -preset ultrafast -tune zerolatency `
-f rtsp -rtsp_transport tcp -listen 1 rtsp://$ip`:$port/live.sdp
