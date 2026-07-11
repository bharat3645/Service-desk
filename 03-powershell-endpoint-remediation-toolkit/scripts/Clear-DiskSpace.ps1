<#
.SYNOPSIS
    Frees up disk space on a workstation using safe, standard cleanup
    targets — for "disk full / low disk space" L1 tickets.

.DESCRIPTION
    Reports free space before/after, clears Windows Temp, user Temp,
    Recycle Bin, Windows Update cache (SoftwareDistribution\Download),
    and browser caches for common browsers. Every deletion is wrapped in
    try/catch so locked files are skipped instead of stopping the script.

.PARAMETER DriveLetter
    Drive to report space for (default C).

.PARAMETER WhatIf
    Built-in PowerShell switch — run with -WhatIf first to preview what
    would be deleted without deleting anything.

.EXAMPLE
    .\Clear-DiskSpace.ps1 -WhatIf

.EXAMPLE
    .\Clear-DiskSpace.ps1 -DriveLetter C

.NOTES
    Run elevated (as Administrator) for full access to system temp/update
    cache folders. Intended as an L1/L2 first-response tool, not a
    replacement for Disk Cleanup / Storage Sense policy.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$DriveLetter = "C"
)

function Get-FreeSpaceGB {
    param([string]$Drive)
    $vol = Get-PSDrive -Name $Drive -ErrorAction SilentlyContinue
    if ($vol) { return [math]::Round($vol.Free / 1GB, 2) }
    return $null
}

function Remove-PathContents {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) {
        Write-Host "  Skipped (not found): $Label" -ForegroundColor DarkGray
        return
    }
    $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    $sizeBefore = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    $removed = 0
    $skipped = 0
    foreach ($item in $items) {
        try {
            if ($PSCmdlet.ShouldProcess($item.FullName, "Delete")) {
                Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
                $removed++
            }
        } catch {
            $skipped++  # file in use / permission denied — expected and safe to skip
        }
    }
    $sizeMB = if ($sizeBefore) { [math]::Round($sizeBefore / 1MB, 1) } else { 0 }
    Write-Host "  $Label -> attempted ~$sizeMB MB across $($items.Count) items | removed: $removed | skipped(in-use): $skipped" -ForegroundColor Green
}

Write-Host "===== Disk Cleanup — Drive $DriveLetter =====" -ForegroundColor Cyan
$before = Get-FreeSpaceGB -Drive $DriveLetter
Write-Host "Free space before: $before GB"
Write-Host ""

Write-Host "[1/5] Windows Temp (C:\Windows\Temp)" -ForegroundColor Cyan
Remove-PathContents -Path "$env:WINDIR\Temp" -Label "Windows Temp"

Write-Host "[2/5] User Temp ($env:TEMP)" -ForegroundColor Cyan
Remove-PathContents -Path $env:TEMP -Label "User Temp"

Write-Host "[3/5] Windows Update Download Cache" -ForegroundColor Cyan
try {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-PathContents -Path "$env:WINDIR\SoftwareDistribution\Download" -Label "WU Cache"
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
} catch {
    Write-Host "  Could not fully manage wuauserv service — cache clear may be partial." -ForegroundColor Yellow
}

Write-Host "[4/5] Recycle Bin" -ForegroundColor Cyan
try {
    if ($PSCmdlet.ShouldProcess("Recycle Bin", "Empty")) {
        Clear-RecycleBin -DriveLetter $DriveLetter -Force -ErrorAction Stop
        Write-Host "  Recycle Bin emptied." -ForegroundColor Green
    }
} catch {
    Write-Host "  Recycle Bin already empty or inaccessible." -ForegroundColor DarkGray
}

Write-Host "[5/5] Browser Caches (Chrome / Edge)" -ForegroundColor Cyan
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
$edgeCache   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
Remove-PathContents -Path $chromeCache -Label "Chrome Cache"
Remove-PathContents -Path $edgeCache -Label "Edge Cache"

Write-Host ""
$after = Get-FreeSpaceGB -Drive $DriveLetter
Write-Host "Free space after:  $after GB" -ForegroundColor Cyan
if ($before -and $after) {
    Write-Host "Space reclaimed:   $([math]::Round($after - $before, 2)) GB" -ForegroundColor Green
}
Write-Host ""
Write-Host "If space is still critically low, escalate to L2 to check for oversized user profiles, orphaned VM/VHD files, or OneDrive sync bloat." -ForegroundColor Yellow
