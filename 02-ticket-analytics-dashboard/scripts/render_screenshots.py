"""
render_screenshots.py
----------------------
Renders real PNG charts directly from tickets.csv (same numbers that live in
dashboard.xlsx) so the README can show genuine, reproducible visuals rather
than a mockup.
"""
import csv
from collections import Counter, defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

PALETTE = ["#1F4E79", "#2E75B6", "#9DC3E6", "#BDD7EE", "#548235", "#A9D18E"]

with open("../data/tickets.csv") as f:
    rows = list(csv.DictReader(f))

n = len(rows)
sla_met = sum(1 for r in rows if r["sla_met"] == "Yes")
fcr = sum(1 for r in rows if r["first_contact_resolution"] == "Yes")
avg_res = sum(float(r["resolution_time_hrs"]) for r in rows) / n
reopen = sum(1 for r in rows if r["reopened"] == "Yes")
avg_csat = sum(float(r["csat_score"]) for r in rows) / n

# ---------- KPI strip ----------
fig, ax = plt.subplots(figsize=(11, 2.2))
ax.axis("off")
kpis = [
    ("Total Tickets", f"{n}"),
    ("SLA Compliance", f"{sla_met/n*100:.1f}%"),
    ("First Contact Resolution", f"{fcr/n*100:.1f}%"),
    ("Avg Resolution (hrs)", f"{avg_res:.2f}"),
    ("Reopen Rate", f"{reopen/n*100:.1f}%"),
    ("Avg CSAT (/5)", f"{avg_csat:.2f}"),
]
for i, (label, value) in enumerate(kpis):
    x = i / len(kpis)
    ax.text(x + 0.02, 0.65, value, fontsize=20, fontweight="bold", color="#1F4E79", transform=ax.transAxes)
    ax.text(x + 0.02, 0.15, label, fontsize=9, color="#595959", transform=ax.transAxes)
plt.suptitle("NorthBridge Retail Ltd — IT Service Desk KPI Summary (Jun 1 – Jul 10, 2026)",
             fontsize=11, fontweight="bold", color="#1F4E79", y=1.05)
plt.tight_layout()
plt.savefig("../screenshots/01_kpi_summary.png", dpi=180, bbox_inches="tight")
plt.close()

# ---------- Ticket volume by category ----------
cat_counts = Counter(r["category"] for r in rows)
cats = sorted(cat_counts, key=cat_counts.get, reverse=True)
vals = [cat_counts[c] for c in cats]
fig, ax = plt.subplots(figsize=(9, 5))
bars = ax.barh(cats[::-1], vals[::-1], color=PALETTE[0])
ax.set_title("Ticket Volume by Category", fontsize=13, fontweight="bold", color="#1F4E79")
ax.set_xlabel("Ticket Count")
for bar, v in zip(bars, vals[::-1]):
    ax.text(bar.get_width() + 1, bar.get_y() + bar.get_height()/2, str(v), va="center", fontsize=9)
plt.tight_layout()
plt.savefig("../screenshots/02_volume_by_category.png", dpi=180)
plt.close()

# ---------- SLA compliance by priority ----------
pri_order = ["P1 - Critical", "P2 - High", "P3 - Moderate", "P4 - Low"]
pri_sla = {}
for p in pri_order:
    sub = [r for r in rows if r["priority"] == p]
    pri_sla[p] = sum(1 for r in sub if r["sla_met"] == "Yes") / len(sub) * 100
fig, ax = plt.subplots(figsize=(8, 5))
bars = ax.bar(pri_order, [pri_sla[p] for p in pri_order], color=PALETTE[1])
ax.axhline(85, color="#C00000", linestyle="--", linewidth=1, label="Target: 85%")
ax.set_ylim(0, 105)
ax.set_ylabel("SLA Compliance %")
ax.set_title("SLA Compliance by Priority", fontsize=13, fontweight="bold", color="#1F4E79")
for i, p in enumerate(pri_order):
    ax.text(i, pri_sla[p] + 2, f"{pri_sla[p]:.1f}%", ha="center", fontsize=9)
ax.legend()
plt.tight_layout()
plt.savefig("../screenshots/03_sla_by_priority.png", dpi=180)
plt.close()

# ---------- Agent performance ----------
agents = sorted(set(r["agent"] for r in rows))
ag_sla = {}
for a in agents:
    sub = [r for r in rows if r["agent"] == a]
    ag_sla[a] = sum(1 for r in sub if r["sla_met"] == "Yes") / len(sub) * 100
agents_sorted = sorted(agents, key=lambda a: ag_sla[a], reverse=True)
fig, ax = plt.subplots(figsize=(9, 5))
bars = ax.bar(agents_sorted, [ag_sla[a] for a in agents_sorted], color=PALETTE[2], edgecolor=PALETTE[0])
ax.axhline(85, color="#C00000", linestyle="--", linewidth=1, label="Target: 85%")
ax.set_ylabel("SLA Compliance %")
ax.set_title("SLA Compliance by Agent", fontsize=13, fontweight="bold", color="#1F4E79")
plt.xticks(rotation=30, ha="right")
ax.legend()
plt.tight_layout()
plt.savefig("../screenshots/04_sla_by_agent.png", dpi=180)
plt.close()

# ---------- Daily ticket trend ----------
daily = defaultdict(int)
for r in rows:
    day = r["created_at"][:10]
    daily[day] += 1
days = sorted(daily)
fig, ax = plt.subplots(figsize=(11, 4.5))
ax.plot(days, [daily[d] for d in days], color=PALETTE[0], marker="o", markersize=3, linewidth=1.5)
ax.set_title("Daily Ticket Volume Trend", fontsize=13, fontweight="bold", color="#1F4E79")
ax.set_ylabel("Tickets Created")
step = max(1, len(days)//10)
ax.set_xticks(days[::step])
plt.xticks(rotation=45, ha="right", fontsize=7)
plt.tight_layout()
plt.savefig("../screenshots/05_daily_trend.png", dpi=180)
plt.close()

print("Rendered 5 screenshots into ../screenshots/")
