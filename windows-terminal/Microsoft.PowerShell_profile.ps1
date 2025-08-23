Invoke-Expression (&starship init powershell)
# Load custom functions and aliases from external file
. "C:\Users\Mehdi\OneDrive\code-tools\windows-terminal\functions.ps1"

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}


function myhelp {
    $customFunctionsPath = "C:\Users\Mehdi\OneDrive\code-tools\windows-terminal\functions.ps1"
    if (-not (Test-Path $customFunctionsPath)) {
        Write-Host "❌ functions.ps1 not found at $customFunctionsPath" -ForegroundColor Red
        return
    }

    Write-Host "`n🧠 Your Custom PowerShell Commands:" -ForegroundColor Cyan
    Write-Host "📄 Loaded from: $customFunctionsPath`n"

    $lines = Get-Content $customFunctionsPath

    # Aliases
    Write-Host "📌 Aliases:" -ForegroundColor Yellow
    $lines | Where-Object { $_ -match '^Set-Alias' } | ForEach-Object {
        if ($_ -match 'Set-Alias\s+-Name\s+(\S+)\s+-Value\s+(.+)$') {
            $name = $matches[1]
            $value = $matches[2]
            Write-Host "  $name ➜ $value"
        }
    }

    # Functions with descriptions
    Write-Host "`n🔧 Functions:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^function\s+(\S+)') {
            $funcName = $matches[1]
            $descLine = if ($i -gt 0 -and $lines[$i - 1] -match '^\s*#') {
                $lines[$i - 1].TrimStart('#').Trim()
            } else {
                "No description"
            }
            Write-Host "  $funcName ➜ $descLine"
        }
    }

    Write-Host "`n📘 Tip: Press Enter to confirm actions, Ctrl+C to cancel."
}
