<#
.SYNOPSIS
    Resets an AD user's password to a secure, randomly generated temporary
    password and forces a change at next logon — standard L1/L2 password
    reset workflow with an auditable transcript.

.DESCRIPTION
    Generates a compliant random temp password (meets typical complexity
    policy: upper, lower, digit, special, 12+ chars), sets it, forces
    change-at-next-logon, and optionally unlocks the account in the same
    step (covers the common "locked out AND forgot password" ticket).

.PARAMETER UserName
    The sAMAccountName of the user.

.PARAMETER AlsoUnlock
    Also clear any lockout as part of the reset.

.EXAMPLE
    .\Reset-UserPassword.ps1 -UserName "jdoe" -AlsoUnlock

.NOTES
    Requires ActiveDirectory module and delegated "Reset password" rights.
    Never echoes the password to console output/logs in plain text beyond
    the single on-screen display to the agent performing the reset —
    do not redirect this script's output to a shared log file.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName,

    [switch]$AlsoUnlock
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-CompliantPassword {
    # Builds a 14-char password guaranteed to include all 4 complexity classes
    $upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ'   # no I/O to avoid confusion
    $lower   = 'abcdefghijkmnopqrstuvwxyz'  # no l
    $digits  = '23456789'                   # no 0/1
    $special = '!@#$%^&*?'

    $rand = [System.Random]::new()
    $chars = @(
        $upper[$rand.Next($upper.Length)]
        $lower[$rand.Next($lower.Length)]
        $digits[$rand.Next($digits.Length)]
        $special[$rand.Next($special.Length)]
    )
    $all = $upper + $lower + $digits + $special
    for ($i = 0; $i -lt 10; $i++) {
        $chars += $all[$rand.Next($all.Length)]
    }
    # shuffle
    $shuffled = $chars | Sort-Object { $rand.Next() }
    return -join $shuffled
}

try {
    $user = Get-ADUser -Identity $UserName -Properties LockedOut, Enabled -ErrorAction Stop
} catch {
    Write-Host "ERROR: Could not find AD user '$UserName'. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (-not $user.Enabled) {
    Write-Host "STOP: Account '$UserName' is disabled. Do not reset — escalate to IAM to confirm this is expected before any action." -ForegroundColor Red
    exit 1
}

$tempPassword = New-CompliantPassword
$securePwd = ConvertTo-SecureString -String $tempPassword -AsPlainText -Force

if ($PSCmdlet.ShouldProcess($UserName, "Reset AD password")) {
    try {
        Set-ADAccountPassword -Identity $UserName -NewPassword $securePwd -Reset -ErrorAction Stop
        Set-ADUser -Identity $UserName -ChangePasswordAtLogon $true -ErrorAction Stop
        Write-Host "SUCCESS: Password reset for '$UserName'. User must change it at next logon." -ForegroundColor Green
        Write-Host ""
        Write-Host "Temporary password (share via a secure/verified channel ONLY — never email/chat):" -ForegroundColor Yellow
        Write-Host "  $tempPassword" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host ""
    } catch {
        Write-Host "ERROR: Password reset failed. $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

if ($AlsoUnlock -and $user.LockedOut) {
    try {
        Unlock-ADAccount -Identity $UserName -ErrorAction Stop
        Write-Host "Account also unlocked." -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Password reset succeeded but unlock failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "Reminder: verify caller identity per your org's identity-verification policy (employee ID + manager confirmation, or ticket-linked verification) BEFORE running this script." -ForegroundColor Cyan
