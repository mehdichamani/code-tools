# Define adapter profiles with DHCP option
$Profiles = @{
    "3.Static" = @{
        "Description" = "OnBoard Edari + PCI Camera"
        "PCI" = @{
            InterfaceAlias = "🔵PCI🔵"
            UseDHCP = $false
            IPv4Address = "172.20.2.254"
            Mask = 24
            IPv4DefaultGateway = "172.20.2.1"
            DNSServer = @("127.0.0.1")
        }
        "OnBoard" = @{
            InterfaceAlias = "🟨OnBoard🟨"
            UseDHCP = $false
            IPv4Address = "172.30.39.30"
            Mask = 24
            IPv4DefaultGateway = "172.30.39.1"
            DNSServer = @("127.0.0.1")
        }
    }
    "1.DHCP" = @{
        "Description" = "Clear All IP modifications and set DHCP to all adaptors including WiFi and LAN."
        "PCI" = @{
            InterfaceAlias = "🔵PCI🔵"
            UseDHCP = $true
        }
        "OnBoard" = @{
            InterfaceAlias = "🟨OnBoard🟨"
            UseDHCP = $true
        }
        "WiFi" = @{
            InterfaceAlias = "Wi-Fi"
            UseDHCP = $true
        }
    }
    "2.CleanStatic" = @{
        "Description" = "WiFi Internet + OnBoard Edari + PCI Camera | no DNS no GetWay"
        "PCI" = @{
            InterfaceAlias = "🔵PCI🔵"
            UseDHCP = $false
            IPv4Address = "172.20.2.254"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }
        "OnBoard" = @{
            InterfaceAlias = "🟨OnBoard🟨"
            UseDHCP = $false
            IPv4Address = "172.30.39.30"
            Mask = 24
            IPv4DefaultGateway = ""
            DNSServer = @("")
        }
    }
}

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
