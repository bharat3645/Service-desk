# Project 1 — End-to-End ServiceNow ITSM Mini-Implementation

## Honesty note on this project's status

ServiceNow Personal Developer Instances (PDIs) require signup with a verified
personal email and are provisioned by ServiceNow itself (usually within
minutes, sometimes up to a few hours). That signup and email verification
step has to happen on your side — it isn't something that can be completed
without access to your inbox. **This README is therefore a complete,
click-by-click build guide with exact configuration values**, not a set of
screenshots from a live instance. Follow it once your PDI is provisioned and
you'll have a fully working ITSM setup in roughly 45–60 minutes. Everywhere
a screenshot would normally go, the guide instead gives you the *exact*
field values and click path so there's no ambiguity.

If you complete this before your interview, take your own screenshots as
you go — that turns this into a genuine, defensible project you built and
can speak to in detail, which is worth far more in an interview than a
canned screenshot would be anyway.

---

## What this project demonstrates

- Working knowledge of the ServiceNow platform structure (Incident, Problem,
  Change, Knowledge, SLA, Workflow) — directly matches "ServiceNow preferred"
  in the JD.
- Ability to configure, not just use, a ticketing system — this is what
  separates L2 from L1.
- Understanding of SLA-driven prioritization and escalation, which is the
  core operating model of any Service Desk.

## Step 1 — Provision your PDI (5–10 min, your side)

1. Go to `developer.servicenow.com` and create a free account (verify your
   email when prompted).
2. Once logged in, go to **Manage → Instance → Request Instance**.
3. Choose the latest general-availability release family offered.
4. Wait for provisioning (usually near-instant to ~20 minutes). You'll get
   an instance URL like `https://devXXXXX.service-now.com` plus an `admin`
   password shown once — save it in a password manager immediately.

## Step 2 — Configure incident categories (10 min)

Navigate: **All → Incident → Create New**, then to configure the choice
list itself go to **System Definition → Choice Lists**, filter Table =
`Incident [incident]`, Element = `category`.

Add these values (Label / Value) — modeled on real Service Desk taxonomy:

| Label | Value |
|---|---|
| Password / Account Access | password_account |
| Network Connectivity | network |
| Hardware Failure | hardware |
| Software / Application | software |
| Access Management | access_mgmt |
| Email / Collaboration Tools | email_collab |

Add a matching `subcategory` dependent choice list for at least
"Password / Account Access" with values: Password Reset, Account Lockout,
MFA Issue — this demonstrates dependent choice list configuration, a
common ServiceNow admin skill.

## Step 3 — Configure SLA definitions (15 min)

Navigate: **Service Level Management → SLA Definitions → New**.

Create four SLAs matching real-world targets:

| Name | Condition | Duration |
|---|---|---|
| P1 - Critical Response | Priority = 1 - Critical | 4 business hours |
| P2 - High Response | Priority = 2 - High | 8 business hours |
| P3 - Moderate Response | Priority = 3 - Moderate | 24 business hours |
| P4 - Low Response | Priority = 4 - Low | 48 business hours |

For each: set **Start condition** = record created, **Stop condition** =
state changes to Resolved, **Schedule** = 8-5 weekdays (or 24x7 if you want
to demonstrate always-on support). Attach the **Duration Type** as a
"Relative Duration" pointing at the field, or a fixed duration per the table
above. Enable **Workflow** on the SLA record and attach the out-of-box
`SLA Notification` workflow so a breach fires a notification — this is the
detail that shows you understand *proactive* SLA management, not just
tracking after the fact.

## Step 4 — Build the assignment/escalation workflow (10 min)

Navigate: **Process Automation → Flow Designer → New Flow** (or classic
Workflow Editor if your PDI still has it).

Build: *"Auto-assign Incident by Category"*
- Trigger: Record Created on `incident`
- Condition: `category` is not empty
- Action: **Look up Record** on the `sys_user_group` table matching a
  naming convention (e.g. group name = category value), then **Update
  Record** to set `assignment_group`.
- Add a second branch: If `priority` = 1 - Critical, also send a
  Notification to the on-call group.

This single flow is enough to demonstrate you understand no-code workflow
automation, which ServiceNow admins use constantly to reduce manual
triage.

## Step 5 — Build the knowledge base (10 min)

Navigate: **Self-Service → Knowledge → Create New**. Create a Knowledge
Base called "IT Service Desk – Self Help" and publish 5 articles:

1. How to Reset Your Password
2. Connecting to Company VPN
3. Requesting New Software / Access
4. Troubleshooting Slow Wi-Fi
5. Setting Up Multi-Factor Authentication (MFA)

Each article: 200–400 words, numbered steps, one "When to contact the
Service Desk instead" callout at the end. Tag each with the matching
`category` value from Step 2 so they surface automatically as suggested
articles when a matching incident is logged (ServiceNow does this
out-of-the-box via the `category`-to-`kb_knowledge` relationship).

## Step 6 — Verification checklist

After building, verify end-to-end by creating one test incident per
priority level and confirming:

- [ ] SLA timer starts automatically and shows correct target duration
- [ ] Incident auto-assigns to the correct group per Step 4's flow
- [ ] Suggested KB article appears on the incident form for a matching category
- [ ] Breaching an SLA (or forcing one via a past-dated test record) fires
      the configured notification

Screenshot each checked item — that verification checklist *is* your
demo script for the interview.

## Talking points for the interview

- "I built a working incident-to-resolution pipeline in a personal
  ServiceNow instance, including SLA-driven prioritization and automated
  assignment routing — not just closing tickets in someone else's queue."
- "I understand the difference between reactive ticket handling and the
  proactive SLA/escalation configuration that keeps a Service Desk from
  becoming a bottleneck."
