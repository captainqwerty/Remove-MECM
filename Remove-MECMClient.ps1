<#
.SYNOPSIS
    Remove MECM Client

.DESCRIPTION
    Removes the MECM Client from a device that has been built with MECM/SCCM but will be Autopilot/Intune managed.

.NOTES
    Author           : CaptainQwerty
    Release Date     : 20/05/2024
    Script Version   : 1.0.0
    GitHub Repo      : https://github.com/CaptainQwerty/Remove-MECM
    ReadMe           : https://github.com/CaptainQwerty/Remove-MECM/blob/main/README.md
#>

<#-----[ Latest Patch Notes ]-----#

Version 1.0.0
    * Initial Creation

#>

#-----[ Requirements ]-----#

#Requires -RunAsAdministrator

#-----[ Configuration ]-----#

$CCMpath = 'C:\Windows\ccmsetup\ccmsetup.exe'
$services = @("ccmsetup","CcmExec","smstsmgr","CmRcService")
$directoriesToRemove = @("CCM","ccmsetup","ccmcahe")
$filesToRemove = @("SMSCFG.ini","SMS*.mif","SMS*.mif")
$registryEntriesToRemove = @("CCM","CCMSetup","SMS","DeviceManageabilityCSP")

#-----[ Execution ]-----#

if (Test-Path $CCMPath) {
    Start-Process -FilePath $CCMPath -Args "/uninstall" -Wait -NoNewWindow
    $CCMProcess = Get-Process ccmsetup -ErrorAction SilentlyContinue
    
    try {
        $CCMProcess.WaitForExit()
    } catch [System.Exception] {
        Write-Output "Error occurred while waiting for CCM Setup to exit: $_"
    }
} else {
    Write-Output "CCM Setup not found at $CCMPath"
}

foreach ($service in $services) {
    Write-Host "Attempting to stop service: $service"
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
}

$CCMProcess = Get-Process ccmexec -ErrorAction SilentlyContinue
if ($CCMProcess) {
    Write-Host "Waiting for ccmexec to exit"
    $CCMProcess.WaitForExit()
    Write-host "ccmexec has exited"
}

Write-Host "Removing WMI Objects"
Get-WmiObject -Query "SELECT * FROM __Namespace WHERE Name='ccm'" -Namespace root | Remove-WmiObject
Get-WmiObject -Query "SELECT * FROM __Namespace WHERE Name='sms'" -Namespace root\cimv2 | Remove-WmiObject

$CurrentPath = "HKLM:\SYSTEM\CurrentControlSet\Services"
foreach ($service in $services) {
    Write-Host "Attempting to remove service: $service"
    Remove-Item -Path $CurrentPath\$service -Force -Recurse -ErrorAction SilentlyContinue
}

$CurrentPath = "HKLM:\SOFTWARE\Microsoft"
foreach ($registryEntry in $registryEntriesToRemove) {
    Write-Host "Attempting to remove registry entry: $registryEntry"
    Remove-Item -Path $CurrentPath\$registryEntry -Force -Recurse -ErrorAction SilentlyContinue
}

$CurrentPath = $env:WinDir
foreach ($directory in $directoriesToRemove) {
    Write-Host "Attempting to remove directory: $directory"
    Remove-Item -Path $CurrentPath\$directory -Force -Recurse -ErrorAction SilentlyContinue
}

foreach ($file in $filesToRemove) {
    Write-Host "Attempting to remove file: $file"
    Remove-Item -Path $CurrentPath\$file -Force -ErrorAction SilentlyContinue
}

Write-Host "MECM Removed. GG."