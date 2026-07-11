# Project 02 — SLA Ticket Analytics Dashboard

**Domain:** Operational Reporting · Service Level Management Analytics
**Status:** Built and independently verified end-to-end (see
Verification Methodology below)

## Objective

Model the operational metrics an IT Service Desk is actually measured
against — SLA attainment, first-contact resolution (FCR), mean
resolution time, reopen rate, and CSAT — as a reproducible, formula-driven
Excel workbook rather than a static report. Demonstrates the analytical
and data-engineering vocabulary of Service Desk performance management,
beyond ticket-handling proficiency alone.

## Directory structure

```
02-sla-ticket-analytics-dashboard/
├── src/
│   ├── generate_ticket_dataset.py     Synthetic dataset generator (seeded, deterministic)
│   ├── build_sla_dashboard.py         Formula-driven Excel workbook builder
│   └── render_kpi_visualizations.py   Independent KPI cross-check + PNG rendering
├── data/
│   └── tickets.csv                    500-record synthetic incident dataset
├── screenshots/                       Rendered KPI visualizations
├── dashboard.xlsx                     Primary deliverable
└── requirements.txt
```

## Build pipeline

```bash
pip install -r requirements.txt
cd src/
python3 generate_ticket_dataset.py      # -> ../data/tickets.csv
python3 build_sla_dashboard.py          # -> ../dashboard.xlsx
python3 render_kpi_visualizations.py    # -> ../screenshots/*.png
```

## Design notes

1. **`generate_ticket_dataset.py`** produces 500 incident records with a
   schema modeled on a real ServiceNow `incident` table export.
   Distributions are intentionally realistic rather than uniform: priority
   mix weighted toward P3/P4 (matching typical queue composition), a
   78%/22% SLA-met/breach split with variance around the target duration,
   and category-conditional first-contact-resolution rates. `random.seed(42)`
   guarantees byte-identical regeneration.

2. **`build_sla_dashboard.py`** writes `dashboard.xlsx` using `openpyxl`
   with **live Excel formulas** (`COUNTIF`, `COUNTIFS`, `AVERAGEIF`,
   `AVERAGE`) referencing the `Raw Data` sheet — KPIs are not
   pre-computed static values. Editing a row and recalculating updates
   every KPI and chart. Native `BarChart`/`PieChart` objects are embedded,
   plus conditional formatting flagging the SLA Compliance KPI when it
   falls below the 85% threshold.

3. **`render_kpi_visualizations.py`** independently recomputes the same
   metrics directly from `tickets.csv` via a separate Python code path
   (not by reading the Excel output) and renders them with `matplotlib` —
   functioning as a cross-check between two independent calculation
   paths.

## Verification methodology

Excel itself was not available in the build environment; correctness was
verified by driving LibreOffice in headless mode to **open
`dashboard.xlsx`, force a full formula recalculation, and export the
computed values** — proving the formulas evaluate correctly, not merely
that they are syntactically well-formed.

This process caught a genuine defect during initial development: ticket
data was written into the workbook as string values (an artifact of
reading from `csv.DictReader`), which silently broke `AVERAGE`/`AVERAGEIF`
on the numeric columns (`resolution_time_hrs`, `csat_score`) — Excel
returned `#DIV/0!` rather than a numeric result. `build_sla_dashboard.py`
was corrected to cast those columns to native numeric types on write. The
subsequent recalculation pass confirmed correct output across all KPIs:

| Metric | Verified Value |
|---|---|
| Total Tickets | 500 |
| SLA Compliance | 74.4% |
| First Contact Resolution | 65.0% |
| Avg Resolution Time | 25.59 hrs |
| Reopen Rate | 3.4% |
| Avg CSAT | 3.99 / 5 |
| Agent-level SLA Compliance range | 69.2% – 76.5% |

## Extending this project

- **Different parameters:** edit the constants at the top of
  `generate_ticket_dataset.py` (record count, SLA targets, date window)
  and re-run the full pipeline.
- **Real ticket data:** replace `data/tickets.csv` with an actual
  ServiceNow incident export matching the documented schema, then run
  `build_sla_dashboard.py` directly.

## Interview talking points

- The dashboard uses live formulas rather than static charts, so it
  remains correct as new ticket data arrives — a data-engineering
  decision, not just a reporting one.
- The verification methodology (independent recalculation via a headless
  spreadsheet engine) caught a real type-coercion defect before delivery,
  demonstrating a "verify, don't assume" engineering habit.
