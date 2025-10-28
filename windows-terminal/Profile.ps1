Invoke-Expression (&starship init powershell)
# Load custom functions and aliases from external file
. "$HOME\OneDrive\code-tools\windows-terminal\functions.ps1"

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
    $customFunctionsPath = "$HOME\OneDrive\code-tools\windows-terminal\functions.ps1"

    if (-not (Test-Path $customFunctionsPath)) {
        Write-Host "❌ functions.ps1 not found at $customFunctionsPath" -ForegroundColor Red
        return
    }

    Write-Host "`n🧠 Your Custom PowerShell Commands:" -ForegroundColor Cyan
    Write-Host "📄 Loaded from: $customFunctionsPath`n"

    $lines = Get-Content $customFunctionsPath

    # ===== Aliases =====
    $aliasList = @()
    $lines | Where-Object { $_ -match '^Set-Alias' } | ForEach-Object {
        if ($_ -match 'Set-Alias\s+-Name\s+(\S+)\s+-Value\s+(.+)$') {
            $aliasList += [PSCustomObject]@{
                Alias   = $matches[1]
                Command = $matches[2]
            }
        }
    }

    if ($aliasList.Count -gt 0) {
        Write-Host "📌 Aliases:" -ForegroundColor Yellow
        # Header
        Write-Host ("{0,-15} {1}" -f "Alias", "Command") -ForegroundColor White
        Write-Host ("{0,-15} {1}" -f "-----", "-------") -ForegroundColor DarkGray

        foreach ($a in $aliasList) {
            Write-Host ("{0,-15}" -f $a.Alias) -ForegroundColor Cyan -NoNewline
            Write-Host (" {0}" -f $a.Command) -ForegroundColor Gray
        }
        Write-Host ""
    }

    # ===== Functions =====
    $funcList = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^function\s+(\S+)') {
            $funcName = $matches[1]
            $descLine = if ($i -gt 0 -and $lines[$i - 1] -match '^\s*#') {
                $lines[$i - 1].TrimStart('#').Trim()
            } else {
                "No description"
            }

            $funcList += [PSCustomObject]@{
                Function    = $funcName
                Description = $descLine
            }
        }
    }

    if ($funcList.Count -gt 0) {
        Write-Host "🔧 Functions:" -ForegroundColor Yellow
        # Header
        Write-Host ("{0,-15} {1}" -f "Function", "Description") -ForegroundColor White
        Write-Host ("{0,-15} {1}" -f "--------", "-----------") -ForegroundColor DarkGray

        foreach ($f in $funcList) {
            Write-Host ("{0,-15}" -f $f.Function) -ForegroundColor Green -NoNewline
            Write-Host (" {0}" -f $f.Description) -ForegroundColor Gray
        }
        Write-Host ""
    }

    Write-Host "📘 Tip: Press Enter to confirm actions, Ctrl+C to cancel."
}

Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
