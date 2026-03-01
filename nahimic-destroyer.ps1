<#
.SYNOPSIS
    Nahimic Destroyer - A complete removal and blocking tool for Nahimic malware/bloatware.
.DESCRIPTION
    This script safely removes Nahimic services, drivers, and leftover files,
    while editing the Windows Registry to permanently block its reinstallation via Windows Update.
#>

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "             NAHIMIC DESTROYER v1.0              " -ForegroundColor White -BackgroundColor DarkCyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# 0. Admin Rights Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] Administrator privileges are required!" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "Please open PowerShell as Administrator and run the command again." -ForegroundColor Yellow
    Write-Host ""
    return
}

Write-Host "[1/5] Blocking Nahimic in Windows Registry..." -ForegroundColor Cyan
$regPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
$regPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs"

if (!(Test-Path $regPath1)) { New-Item -Path $regPath1 -Force | Out-Null }
Set-ItemProperty -Path $regPath1 -Name "DenyDeviceIDs" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath1 -Name "DenyDeviceIDsRetroactive" -Value 1 -Type DWord

if (!(Test-Path $regPath2)) { New-Item -Path $regPath2 -Force | Out-Null }
Set-ItemProperty -Path $regPath2 -Name "1" -Value "ROOT\Nahimic_Mirroring" -Type String
Set-ItemProperty -Path $regPath2 -Name "2" -Value "SWC\VEN_AVOL&AID_0300" -Type String
Set-ItemProperty -Path $regPath2 -Name "3" -Value "SWC\VEN_AVOL&AID_0400" -Type String
Write-Host "  -> Registry block applied successfully." -ForegroundColor Green

Write-Host "`n[2/5] Stopping services and killing processes..." -ForegroundColor Cyan
Stop-Service -Name "Nahimic service" -ErrorAction SilentlyContinue
Set-Service -Name "Nahimic service" -StartupType Disabled -ErrorAction SilentlyContinue
Get-Process -Name "A-Volute*", "Nahimic*" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "  -> Services and processes terminated." -ForegroundColor Green

Write-Host "`n[3/5] Disabling virtual audio devices..." -ForegroundColor Cyan
$nahimicMirroringDevice = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {$_.Class -eq "Media" -and $_.FriendlyName -like "*Nahimic mirroring*"}
if ($nahimicMirroringDevice) {
    $nahimicMirroringDevice | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  -> Virtual device disabled." -ForegroundColor Green
} else {
    Write-Host "  -> Virtual device not found (already clean)." -ForegroundColor DarkGray
}

Write-Host "`n[4/5] Removing drivers from Windows Driver Store..." -ForegroundColor Cyan
$drivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -match "A-Volute|Nahimic" }
if ($drivers) {
    foreach ($driver in $drivers) {
        Write-Host "  -> Deleting $($driver.Driver)..." -ForegroundColor Yellow
        pnputil /delete-driver $driver.Driver /uninstall /force | Out-Null
    }
    Write-Host "  -> Drivers completely removed." -ForegroundColor Green
} else {
    Write-Host "  -> No Nahimic drivers found in the store." -ForegroundColor DarkGray
}

Write-Host "`n[5/5] Cleaning up leftover files, folders, and tasks..." -ForegroundColor Cyan
$pathsToRemove = @(
    "C:\Windows\System32\A-Volute",
    "C:\ProgramData\A-Volute",
    "$env:LOCALAPPDATA\Nahimic",
    "$env:LOCALAPPDATA\A-Volute",
    "C:\Windows\System32\NahimicService.exe",
    "$env:LOCALAPPDATA\NhNotifSys"
)

foreach ($path in $pathsToRemove) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }
}

Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {$_.TaskPath -match "Nahimic|A-Volute"} | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NahimicService" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Nahimic_Mirroring" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\SOFTWARE\A-Volute" -Recurse -ErrorAction SilentlyContinue
Write-Host "  -> Cleanup completed." -ForegroundColor Green

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host " DONE! Nahimic is permanently destroyed.         " -ForegroundColor Black -BackgroundColor Green
Write-Host " Please restart your PC to apply all changes.    " -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
