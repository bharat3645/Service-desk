<#
.SYNOPSIS
    Checks an Active Directory user's lockout/expiry status and optionally
    unlocks the account — the single most common L1 Service Desk request.

.DESCRIPTION
    Wraps Get-ADUser / Unlock-ADAccount with clear pass/fail output and a
    safety confirmation before unlocking, so it is safe to hand to L1 agents
    as a supported tool rather than having them run raw AD cmdlets.

.PARAMETER UserName
    The sAMAccountName of the user to check (e.g. "jdoe").

.PARAMETER Unlock
    If specified, unlocks the account after the check (with confirmation).

.EXAMPLE
    .\Get-ADAccountLockoutStatus.ps1 -UserName "jdoe"

.EXAMPLE
    .\Get-ADAccountLockoutStatus.ps1 -UserName "jdoe" -Unlock

.NOTES
    Requires: RSAT "Active Directory module for Windows PowerShell"
    (Import-Module ActiveDirectory) and permissions delegated to unlock
    accounts — typically via an AD security group granted the
    "Unlock a user's account" delegated control on the OU.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName,

    [switch]$Unlock
)

Import-Module ActiveDirectory -ErrorAction Stop

try {
    $user = Get-ADUser -Identity $UserName -Properties LockedOut, PasswordExpired, `
        PasswordLastSet, PasswordNeverExpires, Enabled, LastBadPasswordAttempt, `
        BadLogonCount, AccountExpirationDate -ErrorAction Stop
} catch {
    Write-Host "ERROR: Could not find AD user '$UserName'. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===== Account Status: $($user.SamAccountName) =====" -ForegroundColor Cyan
Write-Host "Display Name:            $($user.Name)"
Write-Host "Enabled:                 $($user.Enabled)"
Write-Host "Locked Out:              $($user.LockedOut)" -ForegroundColor $(if ($user.LockedOut) { "Red" } else { "Green" })
Write-Host "Password Expired:        $($user.PasswordExpired)"
Write-Host "Password Last Set:       $($user.PasswordLastSet)"
Write-Host "Password Never Expires:  $($user.PasswordNeverExpires)"
Write-Host "Bad Logon Count:         $($user.BadLogonCount)"
Write-Host "Last Bad Password Time:  $($user.LastBadPasswordAttempt)"
Write-Host "Account Expiration:      $(if ($user.AccountExpirationDate) { $user.AccountExpirationDate } else { 'Never' })"
Write-Host ""

# Guidance based on findings — this is what turns a script into a "runbook"
if (-not $user.Enabled) {
    Write-Host "DIAGNOSIS: Account is DISABLED, not locked. Escalate to L2/IAM team — do not attempt unlock." -ForegroundColor Yellow
} elseif ($user.LockedOut) {
    Write-Host "DIAGNOSIS: Account is locked out, most likely from repeated bad password attempts." -ForegroundColor Yellow
    if ($Unlock) {
        if ($PSCmdlet.ShouldProcess($UserName, "Unlock AD Account")) {
            try {
                Unlock-ADAccount -Identity $UserName -ErrorAction Stop
                Write-Host "ACTION TAKEN: Account unlocked successfully." -ForegroundColor Green
                Write-Host "Advise user to update saved credentials on mobile devices / mapped drives to avoid immediate re-lock." -ForegroundColor Cyan
            } catch {
                Write-Host "ERROR: Unlock failed. $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "TIP: Re-run with -Unlock to clear the lockout after confirming identity per verification policy." -ForegroundColor Cyan
    }
} elseif ($user.PasswordExpired) {
    Write-Host "DIAGNOSIS: Password has expired. User must reset at next logon (Ctrl+Alt+Del > Change Password) or via self-service portal." -ForegroundColor Yellow
} else {
    Write-Host "DIAGNOSIS: Account is healthy — not locked, not expired. If user still can't log in, check: caps lock, correct domain\username format, cached credentials on client, or VPN/network path to a DC." -ForegroundColor Green
}
