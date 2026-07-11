---
Article ID: KB0002
Title: VPN Client Connectivity Troubleshooting
Category: Network Connectivity
Workflow State: Published
Audience: Remote / Hybrid Employees
Estimated Resolution Time: 5 minutes
---

# VPN Client Connectivity Troubleshooting

## Resolution steps

1. Launch the VPN client (GlobalProtect / AnyConnect — confirm the
   organization-standard client with IT if unsure).
2. Enter the VPN gateway address if not pre-populated:
   `vpn.company.com`.
3. Authenticate with company username and password.
4. Approve the MFA push notification on the registered device.
5. Confirm the client reports a "Connected" state (typically 10–30
   seconds).

## Troubleshooting

| Symptom | Cause | Resolution |
|---|---|---|
| "Gateway unreachable" | Local internet connectivity issue, not VPN-specific | Confirm open-internet browsing works before troubleshooting VPN further |
| Connects then disconnects repeatedly | Weak Wi-Fi signal or ISP instability | Switch to a wired connection or move closer to the access point |
| MFA push notification not received | Notification permissions disabled on device | Enable notifications for the authenticator application |
| "Certificate error" | Outdated VPN client version | Reinstall the current client version from the Software Center |

## When to contact the Service Desk instead

Escalate if internet connectivity is confirmed functional but the VPN
client fails to launch, returns a licensing error, or access was lost
unexpectedly following a role change or offboarding action.
