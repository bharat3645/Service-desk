---
Topic ID: VA-TOPIC-001
Title: VPN Connectivity Issue
Trigger Keywords: vpn, can't connect vpn, vpn down
Target Table: incident
Workflow State: Design Complete — ready for Virtual Agent Designer implementation
---

# Virtual Agent Topic: VPN Connectivity Issue

## Purpose

Deflect the highest-volume single ticket category in a hybrid workforce —
VPN connectivity — by guiding the requester through diagnostics before a
ticket is created, and creating a ticket automatically, pre-populated
with the captured diagnostic path, only when self-service does not
resolve the issue. This is the standard design pattern for ServiceNow
Virtual Agent and comparable conversational deflection platforms.

## Design rationale

A ticket-logging-only Virtual Agent routes every complaint to a human
queue regardless of whether it required a human. This topic is designed
as a genuine first line of defense: agents should only receive tickets
that require human judgment, with the diagnostic legwork already
complete.

## Conversation flow specification

```
[Trigger: user input matches "vpn" OR selects "VPN Issue" menu option]

Bot: "Can you currently browse the internet normally, outside the VPN?"
     [Yes] [No]

  -> [No]
     Bot: "This is a general connectivity issue, not VPN-specific.
           Try: (1) restart your Wi-Fi/router, (2) check for a local
           ISP outage. Did that resolve it?"
           [Yes, resolved] [Still not working]

        -> [Yes, resolved]
           Bot: "Attempt VPN connection now. Did it succeed?"
                [Yes] [No]
              -> [Yes] -> END — deflected
              -> [No]  -> proceed to VPN Client Check (below)

        -> [Still not working]
           -> CREATE INCIDENT
              category=network, subcategory=general_connectivity, priority=P3
              [END — ticket created, pre-diagnosed]

  -> [Yes] (internet connectivity confirmed functional)
     Bot: "What happens when you attempt to connect?"
          [A: Error message displayed]
          [B: Connection attempt times out]
          [C: MFA push notification not received]

        -> [A: Error message displayed]
           Bot: "Does the error reference a certificate?"
                [Certificate error] [Other / unclear]

              -> [Certificate error]
                 Bot: "Reinstall the current VPN client version from the
                       Software Center, then retry. Resolved?"
                       [Yes] [No]
                    -> [Yes] -> END — deflected
                    -> [No]  -> CREATE INCIDENT
                                subcategory=vpn_client, priority=P3
                                work_notes="client reinstalled, certificate error persists"

              -> [Other / unclear]
                 -> CREATE INCIDENT
                    subcategory=vpn_error, priority=P3
                    work_notes="captured error text: {user_free_text}"

        -> [B: Connection attempt times out]
           Bot: "Try: (1) fully close and relaunch the VPN client,
                 (2) restart the workstation, (3) confirm gateway
                 address vpn.company.com. Resolved?"
                 [Yes] [No]
              -> [Yes] -> END — deflected
              -> [No]  -> CREATE INCIDENT
                          subcategory=vpn_timeout, priority=P2
                          work_notes="timeout persists after client restart, reboot, gateway confirmed"

        -> [C: MFA push notification not received]
           Bot: "Confirm authenticator app notifications are enabled and
                 the device has active data/internet connectivity. Push
                 received now?"
                 [Yes] [No]
              -> [Yes] -> END — deflected
              -> [No]  -> CREATE INCIDENT
                          subcategory=mfa_issue, priority=P2
                          work_notes="MFA push not received, notification permissions confirmed enabled"
```

## Deflection analysis

Of six terminal branches, four resolve via self-service ("END —
deflected") and two escalate to an incident record. Both escalation paths
arrive with the full diagnostic path already captured in `work_notes`,
eliminating agent re-diagnosis time at pickup. For a hybrid workforce
where VPN-related tickets represent approximately 15% of total ticket
volume, a 40% deflection rate on this single topic produces a measurable
reduction in total ticket volume and average handle time.

## ServiceNow implementation steps

1. **Studio → Virtual Agent Designer → Create Topic**, name:
   `VPN Connectivity Issue`.
2. Configure trigger keywords: `vpn`, `can't connect vpn`, `vpn down`.
3. Construct each decision point as a Yes/No or multi-choice block per
   the flow specification above — implementation is entirely
   visual/no-code within Virtual Agent Designer.
4. For each `CREATE INCIDENT` terminal node, configure the built-in
   **Create Record** action targeting the `incident` table, mapping
   captured conversation responses into `description`/`work_notes`, and
   setting `category`/`subcategory`/`priority` per the corresponding
   branch.
5. Validate via Virtual Agent Designer's built-in test chat panel prior
   to publishing to the production portal.
