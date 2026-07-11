<#
.SYNOPSIS
    Verifies whether a piece of software is installed, its version, and
    whether the related Windows service (if any) is running — for
    "app won't open / is it even installed" tickets and post-deployment
    verification after a software push.

.DESCRIPTION
    Checks three sources so nothing is missed: the 32-bit and 64-bit
    Uninstall registry keys (covers most installers), Get-Package
    (covers MSIX/winget-managed apps), and an optional Windows service
    name to confirm the app's backing service is actually running.

.PARAMETER AppNameLike
    Partial name to search for, e.g. "Zoom", "Adobe Acrobat".

.PARAMETER ServiceName
    Optional Windows service name to cross-check (e.g. "ZoomService").

.EXAMPLE
    .\Test-SoftwareInstallation.ps1 -AppNameLike "Zoom"

.EXAMPLE
    .\Test-SoftwareInstallation.ps1 -AppNameLike "CrowdStrike" -ServiceName "CSFalconService"

.NOTES
    Useful for L2 deployment verification: run against a batch of machines
    via Invoke-Command / PSRemoting after a software rollout to confirm
    successful installs at scale.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppNameLike,

    [string]$ServiceName
)

Write-Host "===== Software Verification: '$AppNameLike' on $env:COMPUTERNAME =====" -ForegroundColor Cyan

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$found = @()
foreach ($path in $uninstallPaths) {
    $entries = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$AppNameLike*" }
    if ($entries) { $found += $entries }
}

if ($found.Count -gt 0) {
    Write-Host ""
    Write-Host "Found via registry (Uninstall keys):" -ForegroundColor Green
    $found | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Sort-Object DisplayName -Unique |
        Format-Table -AutoSize
} else {
    Write-Host "Not found via registry uninstall keys." -ForegroundColor Yellow
}

# Cross-check via Get-Package (covers store/winget-managed apps registry misses)
try {
    $pkg = Get-Package -Name "*$AppNameLike*" -ErrorAction SilentlyContinue
    if ($pkg) {
        Write-Host ""
        Write-Host "Found via Get-Package:" -ForegroundColor Green
        $pkg | Select-Object Name, Version, ProviderName | Format-Table -AutoSize
    }
} catch {
    # Get-Package provider not present on this OS build — non-fatal, registry check above is primary source
}

if ($found.Count -eq 0 -and -not $pkg) {
    Write-Host ""
    Write-Host "CONCLUSION: '$AppNameLike' does not appear to be installed on this machine." -ForegroundColor Red
    Write-Host "NEXT STEP: Push install via SCCM/Intune, or verify the deployment task didn't fail silently (check C:\Windows\ccmcache or Intune Management Extension logs)." -ForegroundColor Cyan
}

if ($ServiceName) {
    Write-Host ""
    Write-Host "----- Related Service Check: $ServiceName -----" -ForegroundColor Cyan
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        $color = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "Service '$ServiceName' status: $($svc.Status) | StartType: $($svc.StartType)" -ForegroundColor $color
        if ($svc.Status -ne "Running") {
            Write-Host "ACTION: Consider 'Start-Service -Name $ServiceName' if StartType is Automatic and it should be running." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Service '$ServiceName' not found on this machine." -ForegroundColor Yellow
    }
}
