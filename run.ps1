<#
.SYNOPSIS
    Nahimic Destroyer v1.1 - Now with Windows Update Auto-Hide feature.
#>

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "             NAHIMIC DESTROYER v1.1              " -ForegroundColor White -BackgroundColor DarkCyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# 0. Admin Rights Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] Administrator privileges are required!" -ForegroundColor White -BackgroundColor DarkRed
    return
}

Write-Host "[1/6] Blocking Nahimic in Windows Registry..." -ForegroundColor Cyan
$regPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
$regPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs"
if (!(Test-Path $regPath1)) { New-Item -Path $regPath1 -Force | Out-Null }
Set-ItemProperty -Path $regPath1 -Name "DenyDeviceIDs" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath1 -Name "DenyDeviceIDsRetroactive" -Value 1 -Type DWord
if (!(Test-Path $regPath2)) { New-Item -Path $regPath2 -Force | Out-Null }
Set-ItemProperty -Path $regPath2 -Name "1" -Value "ROOT\Nahimic_Mirroring" -Type String
Set-ItemProperty -Path $regPath2 -Name "2" -Value "SWC\VEN_AVOL&AID_0300" -Type String
Set-ItemProperty -Path $regPath2 -Name "3" -Value "SWC\VEN_AVOL&AID_0400" -Type String

Write-Host "[2/6] Stopping services and killing processes..." -ForegroundColor Cyan
Stop-Service -Name "Nahimic service" -ErrorAction SilentlyContinue
Set-Service -Name "Nahimic service" -StartupType Disabled -ErrorAction SilentlyContinue
Get-Process -Name "A-Volute*", "Nahimic*" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "[3/6] Disabling virtual audio devices..." -ForegroundColor Cyan
Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {$_.Class -eq "Media" -and $_.FriendlyName -like "*Nahimic mirroring*"} | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "[4/6] Removing drivers from Windows Driver Store..." -ForegroundColor Cyan
$drivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -match "A-Volute|Nahimic" }
foreach ($driver in $drivers) { pnputil /delete-driver $driver.Driver /uninstall /force | Out-Null }

Write-Host "[5/6] Cleaning up leftover files and tasks..." -ForegroundColor Cyan
$paths = @("C:\Windows\System32\A-Volute", "C:\ProgramData\A-Volute", "$env:LOCALAPPDATA\Nahimic", "$env:LOCALAPPDATA\A-Volute", "C:\Windows\System32\NahimicService.exe", "$env:LOCALAPPDATA\NhNotifSys")
foreach ($p in $paths) { if (Test-Path $p) { Remove-Item -Path $p -Force -Recurse -ErrorAction SilentlyContinue } }
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {$_.TaskPath -match "Nahimic|A-Volute"} | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# НОВЫЙ ШАГ: СКРЫТИЕ В ЦЕНТРЕ ОБНОВЛЕНИЙ
Write-Host "[6/6] Hiding updates in Windows Update queue..." -ForegroundColor Cyan
try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and IsHidden=0")
    foreach ($Update in $SearchResult.Updates) {
        if ($Update.Title -match "Nahimic" -or $Update.Title -match "A-Volute") {
            $Update.IsHidden = $true
            Write-Host "  -> Hidden: $($Update.Title)" -ForegroundColor Yellow
        }
    }
} catch { Write-Host "  -> Could not access Windows Update Session." -ForegroundColor Red }

Write-Host "`n=================================================" -ForegroundColor Green
Write-Host " DONE! Nahimic is destroyed and hidden.          " -ForegroundColor Black -BackgroundColor Green
Write-Host " Please restart your PC.                         " -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Green
