"""
generate_ticket_dataset.py
---------------------------
Generates a synthetic IT Service Desk incident dataset (n=500) modeled on
a real ServiceNow `incident` table export, for a fictional retail
organization ("NorthBridge Retail Ltd"). Powers the SLA analytics
dashboard build pipeline (build_sla_dashboard.py, render_kpi_visualizations.py).

Schema:
    ticket_id, category, subcategory, priority, channel, agent,
    created_at, resolved_at, resolution_time_hrs, sla_target_hrs,
    sla_met, first_contact_resolution, reopened, csat_score

Determinism: random.seed(42) — output is byte-for-byte reproducible.

Usage:
    python3 generate_ticket_dataset.py
    # writes ../data/tickets.csv
"""
import csv
import random
from datetime import datetime, timedelta

random.seed(42)  # fixed seed — reproducible dataset

CATEGORIES = {
    "Password/Account": ["Password Reset", "Account Lockout", "MFA Issue"],
    "Network": ["VPN Connectivity", "WiFi Issue", "Slow Network"],
    "Hardware": ["Laptop Not Booting", "Printer Issue", "Peripheral Fault"],
    "Software": ["Application Crash", "Install/Update Request", "License Issue"],
    "Access Management": ["New Access Request", "Access Revocation", "Permission Error"],
    "Email/Collaboration": ["Outlook Issue", "Teams/Zoom Issue", "Mailbox Full"],
}

PRIORITY_WEIGHTS = [("P1 - Critical", 0.04), ("P2 - High", 0.16),
                     ("P3 - Moderate", 0.50), ("P4 - Low", 0.30)]

SLA_TARGET_HRS = {"P1 - Critical": 4, "P2 - High": 8, "P3 - Moderate": 24, "P4 - Low": 48}

CHANNELS = ["Phone", "Email", "Self-Service Portal", "Chat", "Walk-in"]

AGENTS = ["A. Sharma", "R. Verma", "P. Singh", "S. Gupta", "N. Iyer",
          "K. Reddy", "M. Khan", "T. Das"]

OUTPUT_PATH = "../data/tickets.csv"
RECORD_COUNT = 500


def weighted_choice(pairs):
    """Selects a value from (value, weight) pairs via cumulative-weight sampling."""
    r = random.random()
    cum = 0
    for val, w in pairs:
        cum += w
        if r <= cum:
            return val
    return pairs[-1][0]


def business_hours_delta(start, hours_budget):
    """Simulates a resolution timestamp with an 78%/22% SLA-met/breach split
    and realistic variance around the target duration."""
    if random.random() < 0.78:
        actual_hours = hours_budget * random.uniform(0.15, 0.95)
    else:
        actual_hours = hours_budget * random.uniform(1.05, 2.8)
    return start + timedelta(hours=actual_hours), round(actual_hours, 2)


def generate_ticket(index, start_date):
    category = random.choice(list(CATEGORIES.keys()))
    subcategory = random.choice(CATEGORIES[category])
    priority = weighted_choice(PRIORITY_WEIGHTS)
    channel = random.choice(CHANNELS)
    agent = random.choice(AGENTS)

    created_at = start_date + timedelta(
        days=random.randint(0, 39),
        hours=random.choice([9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 22, 1]),
        minutes=random.randint(0, 59),
    )
    sla_target = SLA_TARGET_HRS[priority]
    resolved_at, resolution_hrs = business_hours_delta(created_at, sla_target)
    sla_met = resolution_hrs <= sla_target

    fcr = random.random() < (0.68 if category != "Hardware" else 0.45)
    reopened = (not fcr) and random.random() < 0.12
    csat = round(random.gauss(4.3 if sla_met else 3.1, 0.6), 1)
    csat = max(1.0, min(5.0, csat))

    return {
        "ticket_id": f"INC{100000 + index}",
        "category": category,
        "subcategory": subcategory,
        "priority": priority,
        "channel": channel,
        "agent": agent,
        "created_at": created_at.strftime("%Y-%m-%d %H:%M"),
        "resolved_at": resolved_at.strftime("%Y-%m-%d %H:%M"),
        "resolution_time_hrs": resolution_hrs,
        "sla_target_hrs": sla_target,
        "sla_met": "Yes" if sla_met else "No",
        "first_contact_resolution": "Yes" if fcr else "No",
        "reopened": "Yes" if reopened else "No",
        "csat_score": csat,
    }


def main():
    start_date = datetime(2026, 6, 1, 8, 0)
    rows = [generate_ticket(i, start_date) for i in range(1, RECORD_COUNT + 1)]

    fieldnames = list(rows[0].keys())
    with open(OUTPUT_PATH, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Generated {len(rows)} ticket records -> {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
