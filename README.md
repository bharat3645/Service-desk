# IT Service Desk L1/L2 — Advanced Project Portfolio

Built for the HCLTech Lucknow Walk-in Drive (Service Desk L1 & L2,
13 July 2026) and reusable for any IT Service Desk / Technical Support
role requiring ServiceNow, ticketing analytics, and hands-on
troubleshooting skills.

## Honesty statement (read this first)

Every project here is labeled with its real status — nothing is
presented as "live" or "tested" unless it genuinely was. Two constraints
shaped what could be fully executed in the build environment: no live
ServiceNow instance (requires personal signup with email verification)
and no Windows machine (build environment is Linux, and PowerShell
wasn't installable due to network restrictions). Where that mattered,
the affected project's README says so explicitly and gives you the exact
steps to finish verification yourself in minutes.

| Project | Status |
|---|---|
| 1. ServiceNow ITSM Mini-Implementation | Complete build guide with exact configuration values — requires your own PDI signup to execute live |
| 2. Ticket Analytics & SLA Dashboard | **Fully built and independently verified** — real data, real Excel formulas, real recalculation check that caught and fixed a bug |
| 3. PowerShell Troubleshooting Runbook | Fully written, hand-reviewed, passes automated structural syntax check — not executed on live Windows/AD |
| 4. Self-Service KB + Virtual Agent Flow | **Fully written and complete** — 5 KB articles + full decision-tree conversation flow, ready to import into ServiceNow |

## Folder structure

```
service-desk-portfolio/
├── 01-servicenow-itsm-implementation/
│   └── README.md                        # full configuration guide
├── 02-ticket-analytics-dashboard/
│   ├── data/tickets.csv
│   ├── scripts/ (generate_data.py, build_dashboard.py, render_screenshots.py)
│   ├── dashboard.xlsx
│   ├── screenshots/ (6 real renders)
│   └── README.md
├── 03-powershell-troubleshooting-runbook/
│   ├── scripts/ (5 .ps1 scripts + verify_syntax.py)
│   └── README.md
└── 04-selfservice-knowledgebase-virtual-agent/
    ├── kb-articles/ (5 articles)
    ├── virtual-agent-flow.md
    └── (see project 1's guide for import steps)
```

## Note on this GitHub push

The dashboard.xlsx file, its PNG screenshots, and the tickets.csv dataset
are tracked in the full local git history (see the project's other
delivered artifacts) but are reproducible directly from code: running
`scripts/generate_data.py` then `scripts/build_dashboard.py` and
`scripts/render_screenshots.py` in the `02-ticket-analytics-dashboard/`
folder regenerates them exactly (fixed random seed = 42).

## Recommended order to review before Monday

1. **Dashboard (Project 2)** — regenerate or use the version already sent
   to you directly; opens in Excel or Google Sheets and every number
   recalculates live.
2. **KB + Virtual Agent (Project 4)** — read `virtual-agent-flow.md`,
   it's a strong interview talking point on automation thinking even
   before you touch ServiceNow.
3. **PowerShell scripts (Project 3)** — if you have any Windows machine
   available (even personal), run `Test-NetworkConnectivity.ps1` and
   `Clear-DiskSpace.ps1 -WhatIf` once — takes 5 minutes and gives you
   real, defensible "I tested this" screenshots.
4. **ServiceNow (Project 1)** — if time allows, sign up for the free PDI
   and work through the guide. Even getting through Steps 1-3 (instance +
   categories + one SLA) gives you something concrete to screen-share or
   describe in detail.

## How each project maps to the job description

- **"Experience with ticketing tools (ServiceNow preferred)"** →
  Projects 1 and 4 (ServiceNow configuration + Virtual Agent design)
- **"IT Service Desk / Technical Support"** → Project 3 (real
  troubleshooting automation for the highest-frequency ticket types)
- **"Strong English communication skills"** → Project 4's KB articles
  are written for a non-technical end user — clear, numbered, scoped
- **6 months–4 years experience, ready to advance** → Project 2
  demonstrates the metrics/management-level thinking that separates a
  ticket-closer from someone ready for L2 and beyond
