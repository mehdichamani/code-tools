<#
.SYNOPSIS
    Installs a standard set of developer tools using winget and
    configures global Git settings.
#>

Write-Host "--- Starting Tool Installation ---" -ForegroundColor Cyan

# --- 1. Winget Package Installation ---

# Array of package IDs to install
$packages = @(
    "eza.eza",
    "ajeetdsouza.zoxide",
    "Starship.Starship",
    "Microsoft.PowerShell.Preview",
    "Git.Git",
    "LocalSend.LocalSend",
    "Python.Python.3.13"
)

Write-Host "Found $($packages.Count) packages to install."

foreach ($pkg in $packages) {
    Write-Host "`nAttempting to install: $pkg" -ForegroundColor Yellow
    
    # We use --accept-package-agreements and --accept-source-agreements
    # to prevent the script from stopping for user prompts.
    winget install --id $pkg --source winget --accept-package-agreements --accept-source-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully installed $pkg" -ForegroundColor Green
    } else {
        Write-Warning "Installation failed or was skipped for $pkg (Exit code: $LASTEXITCODE)"
    }
}

Write-Host "`n--- Package installation complete ---" -ForegroundColor Cyan


# --- 2. Git Global Configuration ---

Write-Host "`n--- Attempting to configure Git ---" -ForegroundColor Cyan

try {
    # This block will try to run the git commands.
    # It might fail if the script's session PATH hasn't updated yet.
    
    Write-Host "Setting Git user.name..."
    git config --global user.name "mahdichamani"
    
    Write-Host "Setting Git user.email..."
    git config --global user.email "mahdi.chamani20@gmail.com"
    
    Write-Host "Successfully configured Git global settings." -ForegroundColor Green
}
catch [System.Management.Automation.CommandNotFoundException] {
    # This block runs if the 'git' command isn't found
    Write-Warning "Git configuration failed."
    Write-Warning "This is
    common after a new install."
    Write-Warning "Please CLOSE and RE-OPEN this PowerShell window and run these two commands manually:"
    Write-Host "git config --global user.name 'mahdichamani'" -ForegroundColor Yellow
    Write-Host "git config --global user.email 'mahdi.chamani20@gmail.com'" -ForegroundColor Yellow
}
catch {
    # This catches any other errors
    Write-Error "An unexpected error occurred during Git configuration: $_"
}

Write-Host "`n--- Script finished. ---" -ForegroundColor Cyan
Write-Host "Please restart your terminal to ensure all changes (especially Starship and PowerShell Preview) take effect."