# Virtual Agent Topic: "VPN Won't Connect"

## Purpose

Deflect the most common Service Desk call type (VPN connectivity) by
walking the user through diagnostics *before* a ticket is created, and
only creating a ticket automatically — pre-filled with the diagnostic
results — if self-service doesn't resolve it. This is the design pattern
ServiceNow Virtual Agent and most chatbot platforms use, and it maps
directly onto the JD's "ticketing tools (ServiceNow preferred)" and
technical troubleshooting requirements.

## Why this matters for the role

A pure ticket-logger routes every VPN complaint to a human queue. A
Service Desk professional operating at L2 designs the *first line of
defense* so agents only see the tickets that genuinely need a human —
this is the automation mindset that gets someone noticed for
advancement.

## Conversation flow (decision tree)

```
[Trigger: user types "vpn" OR selects "VPN Issue" from menu]

Bot: "Sorry you're having VPN trouble — let's get you connected.
      Can you currently browse the internet normally (outside the VPN)?"
      [Yes] [No]

  -> [No]
     Bot: "That's actually a general internet issue, not VPN-specific.
           Try: 1) Restart your Wi-Fi/router, 2) Check for an ISP outage
           in your area. Did that fix it?"
           [Yes, fixed] [Still not working]

        -> [Yes, fixed]
           Bot: "Great — try connecting to VPN now. Did it work?"
                [Yes] [No]
              -> [Yes] -> Bot: "All set! Have a good day." [END - deflected]
              -> [No]  -> continue to VPN CLIENT CHECK below

        -> [Still not working]
           Bot: "This needs a network specialist. I'm creating a ticket
                 with your diagnostic answers attached so they can start
                 immediately." -> [CREATE TICKET: category=network,
                 subcategory=general_connectivity, priority=P3]
                 [END - ticket created, pre-diagnosed]

  -> [Yes] (internet works fine)
     Bot: "Good — internet's fine, so this is VPN-specific. What happens
           when you try to connect?"
           [A: Error message appears]
           [B: Just spins/times out]
           [C: MFA push never arrives]

        -> [A: Error message]
           Bot: "Can you tell me what the error says, or does it mention
                 'certificate'?"
                 [Certificate error] [Other/not sure]

              -> [Certificate error]
                 Bot: "This usually means your VPN client is outdated.
                       Please reinstall the latest version from the
                       Software Center, then try again. Did that fix it?"
                       [Yes] [No]
                    -> [Yes] -> END - deflected
                    -> [No]  -> CREATE TICKET (subcategory=vpn_client,
                                priority=P3, notes="client reinstalled,
                                certificate error persists")

              -> [Other/not sure]
                 -> CREATE TICKET (subcategory=vpn_error,
                    priority=P3, notes="error message: [user free text
                    captured here]")

        -> [B: Spins/times out]
           Bot: "Let's try three things: 1) Fully close and reopen the
                 VPN client, 2) Restart your computer, 3) Confirm you're
                 using gateway address vpn.company.com. Did any of these
                 help?"
                 [Yes] [No]
              -> [Yes] -> END - deflected
              -> [No]  -> CREATE TICKET (subcategory=vpn_timeout,
                          priority=P2, notes="timeout persists after
                          client restart + reboot + gateway confirmed")

        -> [C: MFA push never arrives]
           Bot: "Please check that notifications are enabled for your
                 authenticator app, and that your phone has an internet/
                 data connection. Did the push come through this time?"
                 [Yes] [No]
              -> [Yes] -> END - deflected
              -> [No]  -> CREATE TICKET (subcategory=mfa_issue,
                          priority=P2, notes="MFA push not received,
                          notifications confirmed enabled")
```

## Deflection metric this design targets

Of the six terminal branches above, four end in self-service resolution
("END — deflected") and only two create a ticket — and both of those
tickets arrive at the agent's queue with the diagnostic path already
attached as notes, meaning zero re-diagnosis time on pickup. If VPN
tickets are ~15% of total ticket volume (a realistic share for a hybrid
workforce), even a 40% deflection rate on this one flow measurably moves
the team's total ticket volume and average handle time — a concrete,
quantifiable case for the automation mindset the JD's "advance your
career" framing is really asking for.

## How to actually implement this in ServiceNow

1. **Studio → Virtual Agent Designer → Create Topic**, name it "VPN
   Connectivity Issue."
2. Add a **Trigger** on keywords: "vpn", "can't connect vpn", "vpn down."
3. Build each decision point as a **Yes/No or Multi-choice block** exactly
   as mapped above — Virtual Agent Designer is visual drag-and-drop, no
   scripting required for this flow.
4. For each "CREATE TICKET" terminal node, use the built-in **"Create
   Record"** action targeting the `incident` table, mapping the
   conversation's captured answers into the `description` and `work_notes`
   fields, and setting `category`/`subcategory`/`priority` per the branch.
5. Test via the **Virtual Agent Designer's built-in test chat panel**
   before publishing to the live portal.
