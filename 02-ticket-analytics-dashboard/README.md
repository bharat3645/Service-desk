# Project 2 — Service Desk Ticket Analytics & SLA Dashboard

**Status: fully built and verified end-to-end.** Every number below was
computed by real Excel formulas against real (synthetic) ticket data, and
independently re-verified using a headless spreadsheet recalculation pass
— see the Verification section for exactly how, including a bug that
verification caught and fixed.

## What this project is

A 500-record synthetic IT Service Desk ticket dataset for a fictional
company ("NorthBridge Retail Ltd"), feeding a live Excel dashboard that
tracks the metrics a real Service Desk is measured on: SLA compliance,
first-contact resolution, average resolution time, reopen rate, and CSAT
— broken down by category, priority, and agent.

## Why this project matters for the JD

The JD asks for Service Desk professionals with ticketing tool experience
who can operate at L1/L2. Most candidates can describe *closing* tickets.
This project demonstrates understanding of how a Service Desk is actually
*measured and managed* — SLA compliance targets, escalation patterns by
priority, and agent-level performance — which is the vocabulary a team
lead or shift manager uses, and shows readiness to grow past pure L1
ticket-taking.

## Repository contents

```
02-ticket-analytics-dashboard/
├── data/
│   └── tickets.csv                 # 500-row synthetic ticket dataset (regenerate via generate_data.py)
├── scripts/
│   ├── generate_data.py            # generates tickets.csv (seeded, reproducible)
│   ├── build_dashboard.py          # builds dashboard.xlsx with live formulas + charts
│   └── render_screenshots.py       # renders the PNG chart screenshots
├── dashboard.xlsx                  # the working deliverable (regenerate via build_dashboard.py)
└── screenshots/                    # regenerate via render_screenshots.py
```

## How it was built (reproducible — not hard-coded numbers)

1. `generate_data.py` creates 500 tickets with realistic distributions:
   priority mix weighted toward P3/P4 (as in real queues), an 78%/22%
   SLA-met/breach split with realistic resolution-time skew, and
   category/channel/agent assignment via weighted randomization with a
   fixed random seed (42) so the dataset is exactly reproducible.
2. `build_dashboard.py` reads `tickets.csv` and writes `dashboard.xlsx`
   using `openpyxl`, with **live Excel formulas** (`COUNTIF`,
   `COUNTIFS`, `AVERAGEIF`, `AVERAGE`) referencing the raw data sheet —
   not pre-computed static numbers. If you edit a row in the "Raw Data"
   tab and hit recalculate, every KPI and chart updates. Native Excel
   `BarChart`/`PieChart` objects are embedded, plus conditional
   formatting that flags the SLA Compliance KPI red if it drops below
   85%.
3. `render_screenshots.py` independently recomputes the same metrics
   straight from the CSV using plain Python (not reading the Excel file)
   and renders matplotlib charts — a second, independent code path
   producing the same numbers, which is itself a form of cross-check.

## Verification (what was actually done to confirm this works)

Excel itself wasn't available in the build environment, so LibreOffice's
headless mode was used to actually **open `dashboard.xlsx`, force a full
formula recalculation, and re-export the computed values** — this proves
the formulas are correct, not just syntactically present.

**This caught a real bug on the first pass**: the ticket data was
initially written into the spreadsheet as text strings (since it came
from a CSV reader), which silently broke `AVERAGE`/`AVERAGEIF` on the
numeric columns (`resolution_time_hrs`, `csat_score`) — Excel returned
`#DIV/0!` instead of a number. `build_dashboard.py` was fixed to cast
those columns to actual numeric types on write, then rebuilt and
re-verified: the recalculation pass confirmed every KPI now computes
correctly (e.g. Total Tickets = 500, SLA Compliance = 74.4%, Avg CSAT =
3.99, agent-level SLA% ranging 69.2%–76.5%).

## How to use / extend it

- Run `generate_data.py` then `build_dashboard.py` then
  `render_screenshots.py`, in that order, from inside `scripts/`.
- Open `dashboard.xlsx` directly in Excel or Google Sheets — everything
  recalculates natively.
- To regenerate with different parameters (more tickets, different SLA
  targets, a different date window), edit the constants at the top of
  `generate_data.py` and re-run all three scripts.
- To swap in *real* ticket export data (e.g. an actual ServiceNow
  incident export as CSV), match the column names in `tickets.csv` and
  point `build_dashboard.py` at your file.

## Talking points for the interview

- "I didn't just chart numbers — I built a dashboard with live formulas
  so it stays correct as new tickets come in, and I verified the
  calculation logic independently rather than trusting it blindly."
- "I can walk through the SLA methodology: how priority determines
  target resolution time, and how compliance is measured against that
  target per ticket."
