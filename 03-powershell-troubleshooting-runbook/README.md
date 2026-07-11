# Project 3 — L1/L2 Troubleshooting Runbook (PowerShell Automation)

## Honesty note on execution status

These scripts are fully written, hand-reviewed, and pass an automated
brace/paren/bracket balance check (details below) — but they were
**not executed against a live Windows machine or Active Directory
domain**, because the build environment for this project is Linux and
has no outbound access to install PowerShell or reach a Windows host.
That's stated plainly rather than presenting simulated console output
as if it were real. Two of the five scripts (`Test-NetworkConnectivity.ps1`,
`Clear-DiskSpace.ps1`) will run as-is on any Windows machine right now.
The other three (`Get-ADAccountLockoutStatus.ps1`, `Reset-UserPassword.ps1`,
`Test-SoftwareInstallation.ps1`'s service-check portion) need the RSAT
Active Directory module and appropriate delegated permissions, which only
exist in a real corporate AD environment.

**Recommended before a walk-in/interview**: run each script once on a
Windows machine (a personal laptop is enough for the two non-AD scripts)
and take real screenshots of the output — that turns "I wrote scripts"
into "I wrote and tested scripts," which is a materially stronger claim
in an interview.

## Why this project matters for the JD

The JD asks for "technical expertise," not just ticket logging. These five
scripts cover the highest-frequency L1/L2 ticket categories directly:
password/lockout, network connectivity, disk space, and software
verification — turning a 10-minute manual diagnostic into a 30-second
automated one, which is exactly the kind of initiative that gets an L1
agent noticed for L2 promotion.

## Scripts

| Script | Ticket type it addresses | Requires |
|---|---|---|
| `Test-NetworkConnectivity.ps1` | "No internet" / "Can't reach [app]" | Standard Windows, no special rights |
| `Get-ADAccountLockoutStatus.ps1` | "I'm locked out" | RSAT AD module + delegated unlock rights |
| `Reset-UserPassword.ps1` | "Forgot my password" | RSAT AD module + delegated reset rights |
| `Clear-DiskSpace.ps1` | "Disk full" / slow PC | Local admin for full effect (works without, with reduced scope) |
| `Test-SoftwareInstallation.ps1` | "App won't open" / post-deployment check | Standard Windows; `-ServiceName` param optional |

Every script includes comment-based help (`Get-Help .\ScriptName.ps1
-Full` works once on a Windows machine), parameter validation, and
try/catch error handling so a missing permission or locked file doesn't
crash the whole run — it logs the failure and continues, which is how
production runbook tooling should behave.

## Verification performed

Since live execution wasn't possible here, correctness was verified the
way you'd verify code without a runtime available:

1. **Structural syntax check**: an automated script (`verify_syntax.py`)
   parses each `.ps1` file character-by-character, correctly skipping
   over PowerShell comments (`#...`), block comments (`<# ... #>`), and
   both single- and double-quoted string literals, then confirms every
   `{`, `(`, and `[` is matched. All 5 scripts pass with zero imbalance.
2. **Manual cmdlet review**: every cmdlet used (`Get-ADUser`,
   `Set-ADAccountPassword`, `Test-NetConnection`, `Get-NetIPConfiguration`,
   `Clear-RecycleBin`, `Get-Package`, etc.) is a real, documented Windows
   PowerShell / RSAT cmdlet with parameters used exactly as documented —
   no invented cmdlet names or parameters.
3. **Logic walkthrough**: traced each script's branches by hand against
   realistic inputs (locked account, disabled account, missing software,
   unreachable host) to confirm the diagnosis/action messaging is correct
   for each case.

Run `python3 verify_syntax.py` from inside `scripts/` to reproduce the check.

## How to actually test these yourself

```powershell
# Safe, no special permissions needed:
.\Test-NetworkConnectivity.ps1 -TargetHost "www.google.com"

# Preview only, deletes nothing:
.\Clear-DiskSpace.ps1 -WhatIf

# Requires RSAT: Install-WindowsFeature RSA-AD-PowerShell (Server) or
# enable "RSAT: Active Directory" optional feature (Windows 10/11):
.\Get-ADAccountLockoutStatus.ps1 -UserName "yourtestaccount"
```

## Talking points for the interview

- "I wrote these to be safe by default — `Clear-DiskSpace.ps1` supports
  `-WhatIf` so you preview before deleting anything, and the password
  reset script never logs the plaintext password to a file, only to the
  console for the agent performing the reset."
- "I built in identity-verification reminders directly into the script
  output for the password reset and unlock tools, because automation
  that skips verification steps is a security risk, not a shortcut."
