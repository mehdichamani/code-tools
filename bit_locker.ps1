# Get all volumes
$allVolumes = Get-BitLockerVolume

# Filter volumes where BitLocker is enabled
$enabledVolumes = $allVolumes | Where-Object {
    $_.KeyProtector.Count -gt 0 -and $_.MountPoint
}

if (-not $enabledVolumes) {
    Write-Host "No BitLocker-enabled volumes found."
    exit
}

# Display volumes with index and lock status
Write-Host "`nBitLocker-Enabled Volumes:"
$index = 0
$enabledVolumes | ForEach-Object {
    $status = if ($_.VolumeStatus -eq $null) {
        '🔒 Locked'
    } elseif ($_.VolumeStatus -eq 'FullyEncrypted') {
        '🔓 Unlocked'
    } else {
        '❌ Not Encrypted'
    }

    Write-Host "$index. Drive Letter: $($_.MountPoint) | Status: $status"
    $index++
}

# Ask user to select volume to lock
$selection = Read-Host "`nEnter the number of the volume you want to lock"
if ($selection -notmatch '^\d+$' -or [int]$selection -ge $enabledVolumes.Count) {
    Write-Host "Invalid selection. Exiting..."
    exit
}

$selectedVolume = $enabledVolumes[$selection]
$driveLetter = $selectedVolume.MountPoint.TrimEnd('\')

# Lock the selected volume
Write-Host "`nLocking drive $driveLetter..."
manage-bde -lock $driveLetter

Write-Host "`nDone."
