# Project 01 — ServiceNow ITSM Configuration Specification

**Domain:** Incident Management · Service Level Management · Process
Automation (Flow Designer) · Knowledge Management
**Deliverable type:** Executable configuration specification (not a
screenshot artifact — see status note below)

## Status

ServiceNow Personal Developer Instances (PDIs) are provisioned against a
verified personal email address and cannot be created programmatically on
a candidate's behalf. This document is therefore authored as a precise,
executable configuration specification: every field value, condition, and
navigation path is stated exactly so the configuration can be reproduced
deterministically against any PDI in approximately 45–60 minutes. Capture
your own screenshots as you execute each step — the resulting artifact is
a verifiably self-built implementation rather than a static asset.

---

## Objective

Demonstrate configuration-level ServiceNow proficiency — not merely
consumption of a pre-built instance — across the platform capabilities
most relevant to an L1/L2 Service Desk role: incident categorization
taxonomy, SLA definition and breach notification, automated
assignment routing (Flow Designer), and knowledge article surfacing.

## Prerequisites

1. A provisioned ServiceNow PDI (`developer.servicenow.com` → **Manage →
   Instance → Request Instance**).
2. `admin` role on the target instance (granted by default on PDI
   provisioning).

## Step 1 — Incident category taxonomy

**Navigation:** `System Definition → Choice Lists` → filter
`Table = Incident [incident]`, `Element = category`.

| Label | Value |
|---|---|
| Password / Account Access | `password_account` |
| Network Connectivity | `network` |
| Hardware Failure | `hardware` |
| Software / Application | `software` |
| Access Management | `access_mgmt` |
| Email / Collaboration Tools | `email_collab` |

Extend with a dependent `subcategory` choice list scoped to
`Password / Account Access` → `password_account`, with values:
`Password Reset`, `Account Lockout`, `MFA Issue`. This demonstrates
dependent-choice-list configuration, a standard ServiceNow
administration competency.

## Step 2 — Service Level Agreement (SLA) definitions

**Navigation:** `Service Level Management → SLA Definitions → New`.

| SLA Name | Condition | Duration | Schedule |
|---|---|---|---|
| P1 - Critical Response | `priority = 1 - Critical` | 4 business hours | 8×5 (or 24×7) |
| P2 - High Response | `priority = 2 - High` | 8 business hours | 8×5 |
| P3 - Moderate Response | `priority = 3 - Moderate` | 24 business hours | 8×5 |
| P4 - Low Response | `priority = 4 - Low` | 48 business hours | 8×5 |

Configuration detail per SLA record:
- **Start condition:** record created
- **Stop condition:** `state` transitions to `Resolved`
- **Duration type:** relative duration bound to the table above
- **Workflow:** attach the out-of-box `SLA Notification` workflow so a
  breach fires an automated notification — this distinguishes proactive
  SLA management from post-hoc SLA reporting.

## Step 3 — Automated assignment flow

**Navigation:** `Process Automation → Flow Designer → New Flow`

**Flow name:** `Auto-assign Incident by Category`

| Component | Configuration |
|---|---|
| Trigger | Record Created, table = `incident` |
| Condition | `category` is not empty |
| Action 1 | Look Up Record — `sys_user_group`, match on category-to-group naming convention |
| Action 2 | Update Record — set `assignment_group` on the triggering incident |
| Branch | If `priority = 1 - Critical` → Notification action targeting the on-call group |

## Step 4 — Knowledge base

**Navigation:** `Self-Service → Knowledge → Create New` → Knowledge Base:
`IT Service Desk – Self Help`

Publish five articles (200–400 words each, numbered remediation steps,
terminal "When to escalate to the Service Desk" section):

1. Password Self-Service Reset
2. VPN Client Connectivity
3. Software Access Request Fulfillment
4. Wireless Network Performance Troubleshooting
5. Multi-Factor Authentication Enrollment

Tag each article with its corresponding `category` value from Step 1 so
ServiceNow's native `category` → `kb_knowledge` relationship surfaces the
article automatically on matching incident records. Fully authored
article content is available in
[Project 04](../04-self-service-kb-and-virtual-agent/knowledge-base-articles/)
and can be imported directly.

## Step 5 — Verification checklist

Create one test incident per priority tier and confirm:

- [ ] SLA timer initializes automatically with the correct target duration
- [ ] Incident auto-assigns to the correct group per the Step 3 flow
- [ ] Suggested KB article surfaces on the incident form for a matching category
- [ ] A forced SLA breach (past-dated test record) triggers the configured notification

Each checked item constitutes verifiable evidence of a working
configuration and serves as a structured interview walkthrough.

## Competencies demonstrated

- Incident taxonomy and dependent choice-list configuration
- SLA definition, breach detection, and proactive notification design
- No-code process automation via Flow Designer
- Knowledge-to-incident relationship configuration
