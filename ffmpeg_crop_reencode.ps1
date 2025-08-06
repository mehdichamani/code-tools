# PowerShell script to batch process MP4 files with ffmpeg and smartblur filter
# Detect user's Downloads folder
$downloads = [Environment]::GetFolderPath('MyDocuments').Replace('Documents', 'Downloads')
if (-not (Test-Path $downloads)) {
    # Fallback for non-standard setups
    $downloads = Join-Path $env:USERPROFILE 'Downloads'
}

# Prompt user for input folder
Write-Host "Enter the input folder path, or press Enter to use your Downloads folder:`n[$downloads]"
$inputDir = Read-Host
if ([string]::IsNullOrWhiteSpace($inputDir)) {
    $inputDir = $downloads
}

# Set output folder as 'output' subfolder in input folder
$outputDir = Join-Path $inputDir 'output'

# Define available filters
$filterOptions = @(
    @{ Name = 'Crop1 (ED)';      Value = 'crop=1080:1080:700:0' }, # crop=w:h:x:y  طول و عرض موقعیت افقی و عمودی به ترتیب
    @{ Name = 'Crop2 (AB)';      Value = 'crop=1080:1080:0:0' },
    @{ Name = 'Light Fix';      Value = 'eq=brightness=0.1:contrast=1.3:saturation=1.2:gamma=1.1'}, #تنظیم نور، کنتراست، گاما
    @{ Name = 'Digital Noise Fix';      Value = 'hqdn3d=1.5:1.5:6:6'}, # کاهش نویز دیجیتال
    @{ Name = 'Strong Sharp & Noise';         Value = 'unsharp=7:7:1.5:7:7:0.0' }, # افزایش وضوح تصویر
    @{ Name = 'Soft Sharp & Noise';      Value = 'smartblur=1.5:-0.35:-3.5:0.65:0.25:2.0' } # بلور هوشمند
    #@{ Name = 'Grayscale'; Value = 'hue=s=0' }, # سیاه و سفید کردن تصویر
    #@{ Name = 'Contrast';  Value = 'eq=contrast=1.5' }, # افزایش کنتراست (contrast=1.0 پیش‌فرض)
    #@{ Name = 'Saturation';Value = 'eq=saturation=2.0' }, # افزایش اشباع رنگ (saturation=1.0 پیش‌فرض)
    #@{ Name = 'FlipH';     Value = 'hflip' }, # برعکس کردن افقی تصویر
    #@{ Name = 'FlipV';     Value = 'vflip' }, # برعکس کردن عمودی تصویر
    #@{ Name = 'Rotate90';  Value = 'transpose=1' }, # چرخش ۹۰ درجه
    #@{ Name = 'FadeIn';    Value = 'fade=t=in:st=0:d=2' } # افکت محو شدن ابتدای ویدیو (۲ ثانیه)
    #@{ Name = 'Scale';     Value = 'scale=1280:720' }, # تغییر اندازه ویدیو به 720p
    #@{ Name = 'Rotate';    Value = 'rotate=45' }, # چرخاندن ویدیو به اندازه 45 درجه
    #@{ Name = 'Setsar';    Value = 'setsar=1:1' }, # تنظیم نسبت تصویر
    #@{ Name = 'Boxblur';   Value = 'boxblur=5' }, # تار کردن تصویر
    #@{ Name = 'Noise';     Value = 'noise=alls=20:allf=t+u' }, # اضافه کردن نویز به تصویر
    #@{ Name = 'Frei0r';    Value = 'frei0r=glow:0.5:0.1' }, # اعمال افکت درخشش
    #@{ Name = 'Overlay';   Value = 'overlay=x=0:y=0' }, # قرار دادن یک ویدیو روی ویدیوی دیگر
    #@{ Name = 'Drawtext';  Value = "drawtext=text='Sample Text':x=100:y=100:fontsize=24:fontcolor=white" } # نوشتن متن روی ویدیو
    # برای افزودن فیلتر جدید، یک خط مشابه اضافه کنید: @{ Name = 'نام', Value = 'پارامتر ffmpeg' }
)
  

# Show filter options
Write-Host "Available filters:"
for ($i = 0; $i -lt $filterOptions.Count; $i++) {
    Write-Host ("[{0}] {1} : {2}" -f ($i+1), $filterOptions[$i].Name, $filterOptions[$i].Value)
}

Write-Host "Enter filter numbers to apply, separated by commas (e.g. 1,3,4):"
$selection = Read-Host
$selectedIndexes = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[1-9][0-9]*$' } | ForEach-Object { [int]$_ - 1 } | Where-Object { $_ -ge 0 -and $_ -lt $filterOptions.Count }

if ($selectedIndexes.Count -eq 0) {
    Write-Host "No valid filters selected. Exiting." -ForegroundColor Yellow
    exit 1
}

# Combine selected filters
$filters = ($selectedIndexes | ForEach-Object { $filterOptions[$_].Value }) -join ','


# Ensure output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Write-Host "Processing all MP4 files in: $inputDir"
Write-Host "Saving to: $outputDir"

# Get MP4 files in input directory
$files = Get-ChildItem -Path $inputDir -Filter *.mp4 -File
if ($files.Count -eq 0) {
    Write-Host "No MP4 files found in $inputDir" -ForegroundColor Yellow
    exit 1
}

foreach ($file in $files) {
    $inputFile = $file.FullName
    $filterNumbers = "(" + (($selectedIndexes | ForEach-Object { $_ + 1 }) -join ',') + ")"
    $outputFile = Join-Path $outputDir ("{0}_new{1}.mp4" -f $file.BaseName, $filterNumbers)
    $ffmpegArgs = @('-i', $inputFile, '-vf', $filters, '-c:v', 'libx264', '-crf', '23', '-preset', 'medium', '-c:a', 'copy', $outputFile)
    & ffmpeg @ffmpegArgs
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

Write-Host "Completed!" -ForegroundColor Green

# ffmpeg -i 'C:\Users\Mehdi\Downloads\input.mp4' -vf 'unsharp=7:7:1.5:7:7:0.0' -c:v libx264 -crf 23 -preset medium -c:a copy 'C:\Users\Mehdi\Downloads\output.mp4'