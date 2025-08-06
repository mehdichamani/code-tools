# مسیر فولدر اسکریپت فعلی (برای پیدا کردن links.txt و cookies.txt)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# چون yt-dlp در PATH هست نیازی به مسیر کامل نداریم
$ytDlp = "yt-dlp"

# مسیرهای فایل‌ها
$cookiesPath = Join-Path $scriptDir "cookies.txt"
$linksFile   = Join-Path $scriptDir "links.txt"
$outputPath  = "C:\Users\Mehdi\Videos\YouTube"  # یا هر مسیر دلخواه

# بررسی فایل‌ها
if (!(Test-Path $linksFile)) {
    Write-Host "❌ File not found: $linksFile" -ForegroundColor Red
    pause
    exit
}

if (!(Test-Path $cookiesPath)) {
    Write-Host "❌ cookies.txt not found at $cookiesPath" -ForegroundColor Red
    pause
    exit
}

# خواندن لینک‌ها
$links = Get-Content $linksFile

# ...existing code...

Write-Host "`n📋 Found $($links.Count) link(s):" -ForegroundColor Cyan
foreach ($link in $links) {
    Write-Host "- $link"
}

$choice = Read-Host "`n🔎 Do you want to fetch video names before downloading? (y/n/exit)"
if ($choice -eq "exit") {
    Write-Host "❌ Exiting." -ForegroundColor Red
    pause
    exit
}

if ($choice -eq "y") {
    $titles = @()
    foreach ($link in $links) {
        Write-Host "`n🔎 Getting info for: $link" -ForegroundColor Yellow
        try {
            $title = & $ytDlp --cookies "$cookiesPath" --get-title $link
            $titles += $title
            Write-Host "🎬 Title: $title"
        } catch {
            Write-Host "⚠️ Could not fetch title. Skipping..." -ForegroundColor DarkRed
            $titles += "[Unknown Title]"
        }
    }
    Write-Host "`n📋 Titles fetched:"
    for ($i=0; $i -lt $links.Count; $i++) {
        Write-Host "$($i+1). $($titles[$i]) - $($links[$i])"
    }
    $confirm = Read-Host "`n✅ Start downloading all videos? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "❌ Download canceled." -ForegroundColor Red
        pause
        exit
    }
}

# If user chose skip or confirmed after fetching names, start downloading
foreach ($link in $links) {
    Write-Host "`n⬇️ Downloading: $link" -ForegroundColor Yellow
    & $ytDlp --cookies "$cookiesPath" --write-auto-sub --sub-lang en --write-thumbnail --embed-thumbnail -f "bv*+ba/b" -o "$outputPath\%(title)s.%(ext)s" $link
}

Write-Host "`n✅ All downloads done." -ForegroundColor Green
pause
# پایان اسکریپت