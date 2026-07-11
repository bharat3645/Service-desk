# IT Service Desk L1/L2 Engineering Portfolio

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A four-project technical portfolio built around the core disciplines of an
ITIL-aligned IT Service Desk: incident/service level management
(ServiceNow), operational analytics (SLA & performance dashboarding),
endpoint remediation automation (PowerShell), and self-service deflection
(knowledge management + conversational AI). Built as preparation for
Service Desk L1/L2 roles requiring hands-on ServiceNow, ticketing, and
technical troubleshooting proficiency.

## Repository architecture

```
service-desk-portfolio/
├── 01-servicenow-itsm-configuration/          Incident/SLA/Knowledge configuration guide (ServiceNow PDI)
├── 02-sla-ticket-analytics-dashboard/         Ticket dataset + formula-driven Excel SLA dashboard
│   ├── src/                                   Data generation, dashboard build, visualization scripts
│   ├── data/                                  Generated ticket dataset (tickets.csv)
│   ├── screenshots/                           Rendered KPI visualizations
│   └── requirements.txt
├── 03-powershell-endpoint-remediation-toolkit/ L1/L2 diagnostic & remediation automation
│   ├── scripts/                               Production PowerShell modules (Verb-Noun convention)
│   └── tests/                                 Static syntax verification harness
├── 04-self-service-kb-and-virtual-agent/      Knowledge base + conversational deflection design
│   ├── knowledge-base-articles/               ITSM-numbered KB articles (KB0001–KB0005)
│   └── virtual-agent-topics/                  Virtual Agent decision-tree topic specification
├── LICENSE
└── README.md
```

## Project index

| ID | Project | Domain | Status |
|----|---------|--------|--------|
| 01 | [ServiceNow ITSM Configuration](01-servicenow-itsm-configuration/) | Incident Management · Service Level Management · Knowledge Management | Configuration guide — executable against any ServiceNow PDI |
| 02 | [SLA Ticket Analytics Dashboard](02-sla-ticket-analytics-dashboard/) | Operational Reporting · Data Engineering | **Built and independently verified** |
| 03 | [PowerShell Endpoint Remediation Toolkit](03-powershell-endpoint-remediation-toolkit/) | IT Automation · Active Directory Administration | Written, statically verified — pending live Windows/AD execution |
| 04 | [Self-Service KB & Virtual Agent](04-self-service-kb-and-virtual-agent/) | Knowledge Management · Conversational Deflection Design | **Complete** — ready for ServiceNow Virtual Agent Designer import |

## Technology stack

| Layer | Tools |
|---|---|
| ITSM Platform | ServiceNow (Incident, Problem, Change, SLM, Knowledge, Flow Designer, Virtual Agent Designer) |
| Data / Analytics | Python 3, `openpyxl` (native Excel formula + chart generation), `matplotlib` |
| Endpoint Automation | PowerShell 5.1 / 7.x, Active Directory module (RSAT) |
| Verification Tooling | LibreOffice headless (spreadsheet formula recalculation), custom static PowerShell syntax analyzer |

## Verification methodology

Every project in this repository states its verification status explicitly
rather than implying completion by omission — see each project's `README.md`
for the specific method used. In summary:

- **Project 02** was verified by forcing a full formula recalculation of the
  generated workbook via a headless spreadsheet engine and diffing the
  computed output against expected values — this process caught and fixed a
  real type-coercion defect (numeric fields written as text, producing
  `#DIV/0!`) before delivery.
- **Project 03** was verified via an automated static analyzer that walks
  each script's token stream (correctly skipping comments and string
  literals) to confirm brace/paren/bracket balance, combined with manual
  cmdlet-signature review against official PowerShell/RSAT documentation.
- **Projects 01 and 04** are configuration/design artifacts whose
  correctness is demonstrated by internal consistency (e.g. category
  taxonomies referenced consistently across SLA definitions, KB tagging,
  and Virtual Agent routing) rather than runtime execution.

## License

Released under the [MIT License](LICENSE).
