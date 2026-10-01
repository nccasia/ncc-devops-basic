#Requires -RunAsAdministrator
<#
.SYNOPSIS
  One-time Hyper-V network setup for the ncc-devops-basic lab.

.DESCRIPTION
  Creates an internal virtual switch "ncc-lab", gives the host the gateway IP
  192.168.56.1 on it, and adds a NAT so the VMs (192.168.56.11-13) can reach
  the internet. Safe to run multiple times.

.EXAMPLE
  # Elevated PowerShell, from the lab-env folder
  .\hyperv\setup-network.ps1
#>
param(
    [string]$SwitchName = "ncc-lab",
    [string]$HostIP     = "192.168.56.1",
    [int]   $PrefixLength = 24,
    [string]$NatName    = "ncc-lab-nat",
    [string]$NatPrefix  = "192.168.56.0/24"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command Get-VMSwitch -ErrorAction SilentlyContinue)) {
    throw "Hyper-V PowerShell module not found. Enable Hyper-V first (see lab-env/README.md)."
}

# 1. Internal switch
if (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue) {
    Write-Host "[OK]   Switch '$SwitchName' already exists"
} else {
    New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
    Write-Host "[NEW]  Created internal switch '$SwitchName'"
}

# 2. Gateway IP on the host side of the switch
$ifAlias = "vEthernet ($SwitchName)"
if (Get-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $HostIP -ErrorAction SilentlyContinue) {
    Write-Host "[OK]   $ifAlias already has $HostIP"
} else {
    New-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $HostIP -PrefixLength $PrefixLength | Out-Null
    Write-Host "[NEW]  Assigned $HostIP/$PrefixLength to $ifAlias"
}

# 3. NAT for internet access from the VMs
if (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue) {
    Write-Host "[OK]   NAT '$NatName' already exists"
} else {
    try {
        New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $NatPrefix | Out-Null
        Write-Host "[NEW]  Created NAT '$NatName' for $NatPrefix"
    } catch {
        Write-Warning "Could not create NAT: $($_.Exception.Message)"
        Write-Warning "Existing NATs (Windows usually allows only one):"
        Get-NetNat | Format-Table Name, InternalIPInterfaceAddressPrefix
        throw
    }
}

Write-Host ""
Write-Host "Done. Now run: vagrant up --provider=hyperv"
