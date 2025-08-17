# ====================================================
# Screen Recorder Full (Recorder + Cleanup + Safe Shutdown)
# ====================================================

# مسیر ذخیره داخل Videos\WLKDF
$videoPath = Join-Path ([Environment]::GetFolderPath("MyVideos")) "WLKDF"
if (!(Test-Path $videoPath)) { New-Item -ItemType Directory -Path $videoPath | Out-Null }

# زمان هر segment (ثانیه) - الان 600 = 10 دقیقه
$segmentTime = 600

# ffmpeg arguments
$args = @(
    "-f", "gdigrab",
    "-framerate", "15",
    "-i", "desktop",
    "-c:v", "libx264",
    "-preset", "ultrafast",
    "-crf", "28",
    "-force_key_frames", "expr:gte(t,n_forced*10)", # هر 10 ثانیه keyframe
    "-f", "segment",
    "-segment_time", $segmentTime,
    "-reset_timestamps", "1",
    "-strftime", "1",
    (Join-Path $videoPath "rec_%Y-%m-%d_%H-%M-%S.mp4")
)

# اجرای ffmpeg در بک‌گراند
$proc = Start-Process -FilePath "ffmpeg" -ArgumentList $args -NoNewWindow -PassThru

# ------------------------------
# Cleanup خودکار 2 روزه
# ------------------------------
$cleanup = {
    if (Test-Path $videoPath) {
        Get-ChildItem $videoPath -File -Include *.mp4 |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) } |
            Remove-Item -Force
    }
}

# Cleanup روزانه با Timer (هر 24 ساعت)
$timer = New-Object Timers.Timer
$timer.Interval = 24*60*60*1000
$timer.AutoReset = $true
$timer.add_Elapsed({ & $cleanup })
$timer.Start()

# ------------------------------
# Safe shutdown/logoff handler
# ------------------------------
Register-EngineEvent PowerShell.Exiting -Action {
    try {
        if ($proc -and !$proc.HasExited) {
            Stop-Process -Id $proc.Id -Force
            Start-Sleep -Seconds 2
        }
    } catch {}
} | Out-Null

# ------------------------------
# نگه داشتن اسکریپت تا پایان
# ------------------------------
$proc.WaitForExit()
