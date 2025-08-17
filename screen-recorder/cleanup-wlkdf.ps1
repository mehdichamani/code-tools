# File: cleanup-wlkdf.ps1
# Delete video files older than 2 days in Videos\WLKDF

$videoPath = Join-Path ([Environment]::GetFolderPath("MyVideos")) "WLKDF"

# چک می‌کنه پوشه وجود داره
if (Test-Path $videoPath) {
    Get-ChildItem $videoPath -File -Include *.mp4 | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) } |
        Remove-Item -Force
}
