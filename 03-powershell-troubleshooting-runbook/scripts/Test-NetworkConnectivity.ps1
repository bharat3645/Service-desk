<#
.SYNOPSIS
    L1/L2 network diagnostic sweep for a single workstation.

.DESCRIPTION
    Runs a standard, repeatable sequence of network checks a Service Desk
    agent would perform for "no internet / can't reach app" tickets:
    local IP config, default gateway reachability, DNS resolution,
    and a traceroute to the target host. Produces a single readable
    report plus a timestamped log file for attaching to the ticket.

.PARAMETER TargetHost
    The host to test connectivity/DNS/traceroute against.
    Defaults to a public host if not supplied.

.PARAMETER LogPath
    Folder to write the timestamped .log report into.

.EXAMPLE
    .\Test-NetworkConnectivity.ps1 -TargetHost "outlook.office365.com"

.NOTES
    Author: Service Desk Portfolio Project
    Tested syntax with PSScriptAnalyzer rules for PS 5.1 and 7.x compatibility.
    Requires: Windows 10/11 or Windows Server with standard network cmdlets
    (Test-Connection, Resolve-DnsName, Test-NetConnection).
#>

[CmdletBinding()]
param(
    [string]$TargetHost = "www.google.com",
    [string]$LogPath = "$env:USERPROFILE\Desktop\ServiceDesk-Logs"
)

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile    = Join-Path $LogPath "NetworkDiagnostic_$timestamp.log"
$report     = [System.Collections.Generic.List[string]]::new()

$report.Add("Network Diagnostic Report")
$report.Add("Generated: $(Get-Date)")
$report.Add("Machine:   $env:COMPUTERNAME")
$report.Add("User:      $env:USERNAME")
$report.Add("Target:    $TargetHost")
$report.Add("")

# 1. Local IP configuration
Write-Section "1. Local IP Configuration"
try {
    $adapters = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }
    foreach ($a in $adapters) {
        $line = "Adapter: $($a.InterfaceAlias) | IPv4: $($a.IPv4Address.IPAddress) | Gateway: $($a.IPv4DefaultGateway.NextHop) | DNS: $($a.DNSServer.ServerAddresses -join ', ')"
        Write-Host $line
        $report.Add($line)
    }
    if (-not $adapters) {
        $msg = "WARNING: No active network adapters found."
        Write-Host $msg -ForegroundColor Yellow
        $report.Add($msg)
    }
} catch {
    $err = "ERROR retrieving IP configuration: $($_.Exception.Message)"
    Write-Host $err -ForegroundColor Red
    $report.Add($err)
}

# 2. Default gateway reachability
Write-Section "2. Default Gateway Reachability"
try {
    $gateway = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4DefaultGateway.NextHop
    if ($gateway) {
        $pingResult = Test-Connection -ComputerName $gateway -Count 4 -ErrorAction Stop
        $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
        $line = "Gateway $gateway reachable. Avg latency: $([math]::Round($avgLatency,1)) ms"
        Write-Host $line -ForegroundColor Green
        $report.Add($line)
    } else {
        $msg = "WARNING: No default gateway found — check physical/Wi-Fi connection."
        Write-Host $msg -ForegroundColor Yellow
        $report.Add($msg)
    }
} catch {
    $err = "FAIL: Default gateway unreachable. $($_.Exception.Message)"
    Write-Host $err -ForegroundColor Red
    $report.Add($err)
}

# 3. DNS resolution
Write-Section "3. DNS Resolution Test"
try {
    $dns = Resolve-DnsName -Name $TargetHost -ErrorAction Stop
    $ips = ($dns | Where-Object { $_.Type -eq "A" }).IPAddress -join ", "
    $line = "DNS resolved $TargetHost -> $ips"
    Write-Host $line -ForegroundColor Green
    $report.Add($line)
} catch {
    $err = "FAIL: DNS resolution failed for $TargetHost. $($_.Exception.Message)"
    Write-Host $err -ForegroundColor Red
    $report.Add($err)
    $report.Add("ACTION: Try 'ipconfig /flushdns' then retest. If it persists, check DNS server config or switch to 8.8.8.8 temporarily to isolate ISP DNS issues.")
}

# 4. End-to-end connectivity + latency
Write-Section "4. End-to-End Connectivity (Test-NetConnection)"
try {
    $tnc = Test-NetConnection -ComputerName $TargetHost -InformationLevel Detailed -ErrorAction Stop
    $line = "PingSucceeded: $($tnc.PingSucceeded) | RemoteAddress: $($tnc.RemoteAddress) | RoundTripTime: $($tnc.PingReplyDetails.RoundtripTime) ms"
    Write-Host $line -ForegroundColor Green
    $report.Add($line)
} catch {
    $err = "FAIL: Test-NetConnection error. $($_.Exception.Message)"
    Write-Host $err -ForegroundColor Red
    $report.Add($err)
}

# 5. Traceroute (identify where the path breaks)
Write-Section "5. Traceroute"
try {
    $trace = Test-NetConnection -ComputerName $TargetHost -TraceRoute -ErrorAction Stop
    $hops = $trace.TraceRoute
    $report.Add("Traceroute hops:")
    for ($i = 0; $i -lt $hops.Count; $i++) {
        $hopLine = "  Hop $($i+1): $($hops[$i])"
        Write-Host $hopLine
        $report.Add($hopLine)
    }
} catch {
    $err = "FAIL: Traceroute error. $($_.Exception.Message)"
    Write-Host $err -ForegroundColor Red
    $report.Add($err)
}

# Save report
$report | Out-File -FilePath $logFile -Encoding UTF8
Write-Section "Report saved"
Write-Host "Log file: $logFile" -ForegroundColor Cyan
