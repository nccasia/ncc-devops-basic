<#
.SYNOPSIS
  Moves a lab VM from "Default Switch" to the ncc-lab switch and restarts it.

.DESCRIPTION
  Called automatically by the Vagrantfile trigger after `vagrant up` with the
  hyperv provider. On first boot the VM is provisioned on "Default Switch"
  (DHCP); the provisioner writes a static IP netplan config. This script then
  connects the VM to the ncc-lab switch, restarts it, and waits until Hyper-V
  reports the expected static IP. Does nothing if already on ncc-lab.
#>
param(
    [Parameter(Mandatory)] [string]$VMName,
    [Parameter(Mandatory)] [string]$ExpectedIP,
    [string]$SwitchName = "ncc-lab",
    [int]   $TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    throw "Switch '$SwitchName' not found. Run hyperv\setup-network.ps1 as Administrator first."
}

$adapter = Get-VMNetworkAdapter -VMName $VMName | Select-Object -First 1
if ($adapter.SwitchName -eq $SwitchName) {
    Write-Host "[$VMName] already on '$SwitchName'"
    exit 0
}

Write-Host "[$VMName] moving from '$($adapter.SwitchName)' to '$SwitchName' and restarting..."
Stop-VM -Name $VMName -Force
Connect-VMNetworkAdapter -VMName $VMName -SwitchName $SwitchName
Start-VM -Name $VMName

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    $ips = (Get-VMNetworkAdapter -VMName $VMName | Select-Object -First 1).IPAddresses
    if ($ips -contains $ExpectedIP) {
        Write-Host "[$VMName] up at $ExpectedIP"
        exit 0
    }
    Start-Sleep -Seconds 3
}

Write-Error "[$VMName] did not report IP $ExpectedIP within $TimeoutSeconds s. Check the VM console in Hyper-V Manager (ip a, cat /etc/netplan/99-ncc-lab.yaml)."
exit 1
