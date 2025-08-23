Write-Host "Changing Shortcut Naming Template..."

# Define registry path and value
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates"
$valueName = "ShortcutNameTemplate"
$valueData = "%s.lnk"

# Check if the registry value exists
if (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue) {
    Write-Host "Shortcut naming template already exists. Overwriting..."
} else {
    Write-Host "Creating new shortcut naming template..."
}

# Try to set the registry value
try {
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name $valueName -Value $valueData
    Write-Host "Shortcut naming template updated successfully!"
} catch {
    Write-Host "Failed to update the shortcut naming template."
}

Read-Host -Prompt "Press Enter to continue"
