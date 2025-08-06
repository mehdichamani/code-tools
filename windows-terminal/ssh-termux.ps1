# File: ssh-termux.ps1

# IP addresses
$ip1 = "192.168.1.50"
$ip0 = "192.168.0.50"

# Get input from user
$input = Read-Host "Enter IP address (or '1' for $ip1, '0' for $ip0)"

# Determine which IP to use
$finalIP = switch ($input) {
    "1" { $ip1 }
    "0" { $ip0 }
    "" { $ip1 }  # Default to 192.168.1.50 if empty
    default { $input }  # Use the entered IP if not 0 or 1
}

# Run SSH command
ssh -i "~/.ssh/id_multiusekey" -p 8022 u0_a355@$finalIP

# Pause before closing
pause