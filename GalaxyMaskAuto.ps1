# Step 0: Check for Admin Rights
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Output "Step 0: Checking if the script is running as Administrator..."
if (-not (Test-Admin)) {
    Write-Output "Error: This script requires Administrator privileges. Please run it as Administrator."
    Write-Output "Press any key to exit..."
    [System.Console]::ReadKey() | Out-Null
    exit
}

Write-Output "Admin rights confirmed. Continuing..."

$taskName = "SamsungNotesBypass"
$scriptPath = "$env:USERPROFILE\Documents\SamsungNotesBypass.ps1"

# Step 1: Create the Samsung Notes Bypass Script
Write-Output "Step 1: Creating the Samsung Notes Bypass script if it does not exist..."
if (!(Test-Path $scriptPath)) {
    Write-Output "Creating the Samsung Notes bypass script at: $scriptPath"

    @'
# Samsung Notes Bypass Script
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemProductName /t REG_SZ /d "NP960XFG-KC4UK" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemManufacturer /t REG_SZ /d "Samsung" /f
Start-Process "shell:AppsFolder\SAMSUNGELECTRONICSCoLtd.SamsungNotes_wyx1vj98g3asy!App"
Start-Sleep -Seconds 3
$process = Get-Process | Where-Object { $_.MainWindowTitle -match 'Samsung Notes' }
$process.CloseMainWindow()
'@ | Set-Content -Path $scriptPath -Encoding UTF8

    Write-Output "Script created successfully at: $scriptPath"
} else {
    Write-Output "Samsung Notes bypass script already exists at: $scriptPath"
}

# Step 2: Check if the Task Already Exists
Write-Output "Step 2: Checking if the scheduled task already exists..."
$taskExists = schtasks /query /tn $taskName 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Output "Task not found. Proceeding to create the scheduled task..."
    # Step 3: Create the Scheduled Task
    Write-Output "Creating the scheduled task to run the script on logon..."

    schtasks /create /tn $taskName /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" /sc onlogon /rl highest /f

    Write-Output "Task created successfully!"
} else {
    Write-Output "Scheduled task '$taskName' already exists. Skipping task creation."
}

# Step 4: Run the Task Immediately
Write-Output "Step 4: Running the scheduled task now..."
Start-ScheduledTask -TaskName $taskName

Write-Output "Task has been run. It should now execute as planned."

# Step 5: Pause at the End
Write-Output "Step 5: Press any key to exit the script..."
[System.Console]::ReadKey() | Out-Null
