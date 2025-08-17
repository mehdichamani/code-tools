# File: screen-recorder-test.ps1
# Continuous 1m chunks screen recorder with ffmpeg (test mode, Windows friendly)

$videoPath = Join-Path ([Environment]::GetFolderPath("MyVideos")) "WLKDF"
if (!(Test-Path $videoPath)) {
    New-Item -ItemType Directory -Path $videoPath | Out-Null
}

$args = @(
    "-f", "gdigrab",
    "-framerate", "15",
    "-i", "desktop",
    "-c:v", "libx264",
    "-preset", "ultrafast",
    "-crf", "28",
    "-f", "segment",
    "-segment_time", "60",        # ⬅️ ۱ دقیقه
    "-reset_timestamps", "1",
    "-strftime", "1",             # ⬅️ برای فعال‌سازی زمان در اسم فایل
    (Join-Path $videoPath "rec_%Y-%m-%d_%H-%M-%S.mp4")
)

$proc = Start-Process -FilePath "ffmpeg" -ArgumentList $args -NoNewWindow -PassThru

Register-EngineEvent PowerShell.Exiting -Action {
    try {
        if (!$proc.HasExited) {
            Stop-Process -Id $proc.Id -Force
            Start-Sleep -Seconds 2
        }
    } catch {}
} | Out-Null

$proc.WaitForExit()
