# Project 04 — Self-Service Knowledge Base & Virtual Agent Design

**Domain:** Knowledge Management · Conversational Deflection Design ·
Process Automation
**Status:** Complete — content authored and ready for direct import into
a ServiceNow Knowledge Base and Virtual Agent Designer topic

## Objective

Design the self-service layer that sits in front of the Service Desk
queue: structured knowledge articles for direct end-user consumption, and
a Virtual Agent conversation topic that resolves common issues through
guided diagnostics before a ticket is ever created. This reflects the
automation-first mindset increasingly expected at L2 — reducing inbound
ticket volume rather than only processing it faster.

## Directory structure

```
04-self-service-kb-and-virtual-agent/
├── knowledge-base-articles/
│   ├── KB0001-password-self-service-reset.md
│   ├── KB0002-vpn-client-connectivity-troubleshooting.md
│   ├── KB0003-software-access-request-fulfillment.md
│   ├── KB0004-wireless-network-performance-troubleshooting.md
│   └── KB0005-multi-factor-authentication-enrollment.md
└── virtual-agent-topics/
    └── VA-TOPIC-001-vpn-connectivity-issue.md
```

Article identifiers (`KB0001`–`KB0005`) follow the numbering convention
used by ServiceNow's `kb_knowledge` table, so the content can be imported
directly with matching Number field values.

## Knowledge base article index

| ID | Title | Category | Est. Resolution Time |
|---|---|---|---|
| KB0001 | Password Self-Service Reset | Password / Account Access | 3 min |
| KB0002 | VPN Client Connectivity Troubleshooting | Network Connectivity | 5 min |
| KB0003 | Software Access Request Fulfillment | Access Management | 2 min submission |
| KB0004 | Wireless Network Performance Troubleshooting | Network Connectivity | 5 min |
| KB0005 | Multi-Factor Authentication Enrollment | Password / Account Access | 5 min |

Each article follows a consistent structure — prerequisites, numbered
remediation steps, a symptom/cause/fix troubleshooting table where
applicable, and a terminal "When to contact the Service Desk instead"
section defining the escalation boundary. This structure is deliberate:
an escalation boundary that is too vague causes either premature
escalation (defeats the purpose of self-service) or unsafe self-service
attempts on issues that require identity verification.

## Virtual Agent topic: VPN Connectivity Issue

`virtual-agent-topics/VA-TOPIC-001-vpn-connectivity-issue.md` specifies a
complete decision-tree conversation flow that triages VPN connectivity
complaints — the highest-volume single ticket category in most hybrid
workforces — before a ticket is created. Of six terminal branches in the
flow, four resolve via self-service and two escalate to a ticket that
arrives pre-populated with the full diagnostic path already captured in
`work_notes`, eliminating agent re-diagnosis time on pickup.

See the topic specification for the full flow diagram, the deflection
rationale, and step-by-step ServiceNow Virtual Agent Designer
implementation instructions.

## Interview talking points

- Self-service content here is written to a defined structural standard
  (prerequisites → steps → troubleshooting table → escalation boundary),
  not ad hoc — that structure is what makes a knowledge base scale past a
  handful of articles without becoming inconsistent.
- The Virtual Agent topic is designed around a measurable deflection
  rate, not just "having a chatbot" — the design explicitly reasons about
  what fraction of a specific ticket category can be resolved without
  human intervention.
