# Project 03 — PowerShell Endpoint Remediation Toolkit

**Domain:** IT Automation · Active Directory Administration · Endpoint
Diagnostics
**Status:** Written and statically verified — not yet executed against a
live Windows/Active Directory environment (see Status Note)

## Status note

Script logic was authored and reviewed in a Linux build environment with
no route to install PowerShell Core or reach a Windows/AD host (outbound
package installation was restricted). Rather than fabricate simulated
console output, correctness is demonstrated through static verification
(below) and the status is stated plainly. `Test-NetworkConnectivity.ps1`
and `Clear-DiskSpace.ps1` require no elevated permissions or AD
connectivity and will execute as-is on any Windows machine; the remaining
three require the RSAT Active Directory module and delegated permissions
that only exist in a domain-joined environment. Executing each script
once against a live target and capturing real output is the recommended
next step before relying on this toolkit operationally.

## Objective

Automate the five highest-frequency L1/L2 diagnostic and remediation
workflows — account lockout, password reset, network connectivity
triage, disk space remediation, and software installation verification —
converting a manual, multi-minute diagnostic into a single parameterized
command with structured, actionable output.

## Directory structure

```
03-powershell-endpoint-remediation-toolkit/
├── scripts/
│   ├── Test-NetworkConnectivity.ps1        Network diagnostic sweep (IP, gateway, DNS, traceroute)
│   ├── Get-ADAccountLockoutStatus.ps1      AD account lockout/expiry check + guided unlock
│   ├── Reset-UserPassword.ps1              AD password reset with compliant temp-password generation
│   ├── Clear-DiskSpace.ps1                 Safe disk cleanup (temp, WU cache, recycle bin, browser cache)
│   └── Test-SoftwareInstallation.ps1       Registry + package-manager software verification
└── tests/
    └── validate_powershell_syntax.py       Static structural syntax validator (CI-gate compatible)
```

## Script reference

| Script | Ticket category addressed | Runtime requirements |
|---|---|---|
| `Test-NetworkConnectivity.ps1` | Connectivity failures ("no internet", "can't reach [app]") | Standard Windows — no elevated rights |
| `Get-ADAccountLockoutStatus.ps1` | Account lockout | RSAT ActiveDirectory module + delegated unlock rights |
| `Reset-UserPassword.ps1` | Password reset | RSAT ActiveDirectory module + delegated reset rights |
| `Clear-DiskSpace.ps1` | Low disk space / degraded performance | Local administrator for full-scope cleanup (degrades gracefully without) |
| `Test-SoftwareInstallation.ps1` | Application availability / post-deployment verification | Standard Windows; `-ServiceName` parameter optional |

Every script implements PowerShell comment-based help (`Get-Help
.\<ScriptName>.ps1 -Full`), explicit parameter validation, and
`try`/`catch` error handling scoped so a single failure (locked file,
missing permission) is logged and the script continues rather than
terminating — the standard resilience pattern for production runbook
tooling.

## Verification methodology

With live execution unavailable, correctness was established via three
independent methods:

1. **Static structural validation** (`tests/validate_powershell_syntax.py`)
   — parses each script's character stream, correctly excluding comments
   and string literals, and confirms brace/paren/bracket balance. Exits
   non-zero on failure, making it usable as a CI gate. All five scripts
   currently pass.
2. **Cmdlet-signature review** — every cmdlet invoked (`Get-ADUser`,
   `Set-ADAccountPassword`, `Test-NetConnection`, `Get-NetIPConfiguration`,
   `Clear-RecycleBin`, `Get-Package`, etc.) was cross-checked against
   official Microsoft PowerShell/RSAT documentation for correct parameter
   names and types.
3. **Manual control-flow tracing** — each script's branches were traced
   by hand against representative inputs (locked account, disabled
   account, missing software, unreachable host) to confirm diagnostic
   messaging is correct for each case.

```bash
cd tests/
python3 validate_powershell_syntax.py
# Clear-DiskSpace.ps1: PASS
# Get-ADAccountLockoutStatus.ps1: PASS
# Reset-UserPassword.ps1: PASS
# Test-NetworkConnectivity.ps1: PASS
# Test-SoftwareInstallation.ps1: PASS
```

## Execution examples

```powershell
# No special permissions required
.\Test-NetworkConnectivity.ps1 -TargetHost "outlook.office365.com"

# Preview mode — no deletions performed
.\Clear-DiskSpace.ps1 -WhatIf

# Requires RSAT: Install-WindowsFeature RSA-AD-PowerShell (Server)
#             or enable "RSAT: Active Directory" optional feature (Win 10/11)
.\Get-ADAccountLockoutStatus.ps1 -UserName "jdoe" -Unlock
```

## Security design decisions

- `Clear-DiskSpace.ps1` implements `SupportsShouldProcess`, enabling
  `-WhatIf` preview semantics before any deletion occurs.
- `Reset-UserPassword.ps1` never persists the generated temporary
  password to disk or log output — it is surfaced once to the console
  for the executing agent and explicitly documented as unsafe to
  redirect to a shared log file.
- Both AD-scoped scripts (`Get-ADAccountLockoutStatus.ps1`,
  `Reset-UserPassword.ps1`) print an explicit caller-identity-verification
  reminder before completing, reflecting standard Service Desk security
  policy rather than treating automation as a bypass of verification
  controls.
