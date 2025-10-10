# Define adapter profiles with DHCP option
$Profiles = @{
    "DHCP" = @{
        "Description" = "full DHCP for all interfaces"
        "PCI (G4)" = @{
            InterfaceAlias = "PCI (G4)"
            UseDHCP = $true
        }
        "OnBoard (G5)" = @{
            InterfaceAlias = "OnBoard (G5)"
            UseDHCP = $true
        }
        "USB (G6)" = @{
            InterfaceAlias = "USB (G6)"
            UseDHCP = $true
        }        
        "WiFi" = @{
            InterfaceAlias = "Wi-Fi"
            UseDHCP = $true
        }
    }
    "normal" = @{
        "Description" = "internet on usb camera and edari"
        "PCI (G4)" = @{
            InterfaceAlias = "PCI (G4)"
            UseDHCP = $false
            IPv4Address = "172.20.2.210"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }
        "OnBoard (G5)" = @{
            InterfaceAlias = "OnBoard (G5)"
            UseDHCP = $false
            IPv4Address = "172.30.39.30"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }
        "USB (G6)" = @{
            InterfaceAlias = "USB (G6)"
            UseDHCP = $true
        }        
    }
    "cisco" = @{
        "Description" = "cisco config vlan"
        "PCI (G4)" = @{
            InterfaceAlias = "PCI (G4)"
            UseDHCP = $false
            IPv4Address = "172.20.2.210"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }
        "OnBoard (G5)" = @{
            InterfaceAlias = "OnBoard (G5)"
            UseDHCP = $false
            IPv4Address = "172.30.39.30"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }
        "USB (G6)" = @{
            InterfaceAlias = "USB (G6)"
            UseDHCP = $false
            IPv4Address = "192.168.30.2"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }        
    }
}

# Check for command line argument
if ($args.Count -gt 0) {
    $profile = $args[0]
    # Check if profile exists (case-insensitive)
    $matchedProfile = $Profiles.Keys | Where-Object { $_ -eq $profile }
    if (-not $matchedProfile) {
        Write-Host "Profile '$profile' not found. Available profiles:" -ForegroundColor Red
        $Profiles.Keys | Sort-Object | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Yellow
        }
        exit
    }
    $profile = $matchedProfile
} else {
    # Display available mods with index and descriptions
    Write-Host "Available mods:"
    $modNames = $Profiles.Keys | Sort-Object
    for ($i = 0; $i -lt $modNames.Count; $i++) {
        $description = $Profiles[$modNames[$i]].Description
        Write-Host "$($i + 1). $($modNames[$i]) - $description"
    }

    # Get selection from user
    $selection = Read-Host "Enter mod number (1-$($modNames.Count))"
    $selectedIndex = [int]$selection - 1

    if ($selectedIndex -ge 0 -and $selectedIndex -lt $modNames.Count) {
        $profile = $modNames[$selectedIndex]
    } else {
        Write-Host "Invalid selection. Please enter a number between 1 and $($modNames.Count)."
        exit
    }
}

if ($Profiles.ContainsKey($profile)) {
    foreach ($adapter in $Profiles[$profile].GetEnumerator()) {
        # Skip the Description entry
        if ($adapter.Key -eq "Description") { continue }
        
        $a = $adapter.Value
        $alias = $a.InterfaceAlias

        if ($a.UseDHCP) {
            # Remove old static routes and IPs
            $oldRoutes = Get-NetRoute -InterfaceAlias $alias -ErrorAction SilentlyContinue | Where-Object { $_.NextHop -ne "0.0.0.0" }
            foreach ($route in $oldRoutes) {
                Remove-NetRoute -InterfaceAlias $alias -NextHop $route.NextHop -Confirm:$false -ErrorAction SilentlyContinue
            }
            $oldIPs = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue
            foreach ($ip in $oldIPs) {
                Remove-NetIPAddress -InterfaceAlias $alias -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
            }
            
            # Enable DHCP for IP and DNS
            Set-NetIPInterface -InterfaceAlias $alias -Dhcp Enabled -ErrorAction SilentlyContinue
            Set-DnsClientServerAddress -InterfaceAlias $alias -ResetServerAddresses -ErrorAction SilentlyContinue
            Write-Host "Enabled DHCP for $alias on profile $profile."
        } else {
            # Disable DHCP
            Set-NetIPInterface -InterfaceAlias $alias -Dhcp Disabled -ErrorAction SilentlyContinue

            # Remove old IP config
            $oldIPs = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue
            foreach ($ip in $oldIPs) {
                Remove-NetIPAddress -InterfaceAlias $alias -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
            }

            # Set static IP with or without gateway
            if ($a.IPv4Address -and $a.Mask) {
                if ($a.IPv4DefaultGateway -and $a.IPv4DefaultGateway -ne "") {
                    New-NetIPAddress -InterfaceAlias $alias -IPAddress $a.IPv4Address -PrefixLength $a.Mask -DefaultGateway $a.IPv4DefaultGateway -ErrorAction SilentlyContinue
                } else {
                    New-NetIPAddress -InterfaceAlias $alias -IPAddress $a.IPv4Address -PrefixLength $a.Mask -ErrorAction SilentlyContinue
                }
            }

            # Set static DNS servers only if not empty
            if ($a.DNSServer -and $a.DNSServer[0] -ne "") {
                Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses $a.DNSServer -ErrorAction SilentlyContinue
            } else {
                # Clear both IPv4 and IPv6 DNS servers
                Set-DnsClientServerAddress -InterfaceAlias $alias -ResetServerAddresses -ErrorAction SilentlyContinue
                Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses @() -ErrorAction SilentlyContinue
            }
            Write-Host "Configured static IP for $alias on profile $profile."
        }
    }
} else {
    Write-Host "Profile '$profile' not found."
}
