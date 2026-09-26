#!/usr/bin/env python3

import os
import re
import glob
import csv
from datetime import datetime

# ==================================================
# Config
# ==================================================
LOG_DIR = "logs/*.log"
HTML_OUT = "report.html"
CSV_OUT  = "report.csv"

# ==================================================
# Regex cho UVM log
# ==================================================
RE_SB_SUMMARY     = re.compile(r"Scoreboard Summary: Total=(\d+) WR=(\d+) RD=(\d+) ERR=(\d+)")
RE_REPORT_ERRORS  = re.compile(r"UVM_ERROR\s*:\s*(\d+)")
RE_REPORT_WARN    = re.compile(r"UVM_WARNING\s*:\s*(\d+)")

# ==================================================
# Parse log
# ==================================================
def parse_log(path):
    with open(path, "r", errors="ignore") as f:
        content = f.read()

    testname = os.path.basename(path).replace(".log", "")

    total = writes = reads = sb_errors = 0
    uvm_errors = uvm_warnings = 0

    m = RE_SB_SUMMARY.search(content)
    if m:
        total     = int(m.group(1))
        writes    = int(m.group(2))
        reads     = int(m.group(3))
        sb_errors = int(m.group(4))

    m = RE_REPORT_ERRORS.search(content)
    if m:
        uvm_errors = int(m.group(1))

    m = RE_REPORT_WARN.search(content)
    if m:
        uvm_warnings = int(m.group(1))

    status = "PASS"
    if sb_errors > 0 or uvm_errors > 0:
        status = "FAIL"

    return {
        "test": testname,
        "status": status,
        "total": total,
        "writes": writes,
        "reads": reads,
        "sb_errors": sb_errors,
        "uvm_errors": uvm_errors,
        "uvm_warnings": uvm_warnings,
    }

# ==================================================
# Collect results
# ==================================================
results = []
for logfile in sorted(glob.glob(LOG_DIR)):
    results.append(parse_log(logfile))

# FAIL first
results.sort(key=lambda x: x["status"])

# ==================================================
# CSV Report
# ==================================================
with open(CSV_OUT, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow([
        "Test","Status","Total","Writes","Reads",
        "SB Errors","UVM Errors","UVM Warnings"
    ])
    for r in results:
        writer.writerow([
            r["test"], r["status"], r["total"], r["writes"], r["reads"],
            r["sb_errors"], r["uvm_errors"], r["uvm_warnings"]
        ])

# ==================================================
# Statistics
# ==================================================
total_tests   = len(results)
pass_tests    = sum(1 for r in results if r["status"] == "PASS")
fail_tests    = total_tests - pass_tests

total_writes  = sum(r["writes"] for r in results)
total_reads   = sum(r["reads"] for r in results)
total_sb_err  = sum(r["sb_errors"] for r in results)
total_uvm_err = sum(r["uvm_errors"] for r in results)
total_uvm_warn= sum(r["uvm_warnings"] for r in results)

now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# ==================================================
# HTML Report
# ==================================================
html = f"""
<html>
<head>
<title>UVM Regression Report</title>
<style>
body {{ font-family: Arial; margin: 20px; }}
table {{ border-collapse: collapse; width: 90%; margin: auto; margin-bottom: 30px; }}
th, td {{ border: 1px solid #ccc; padding: 8px; text-align: center; }}
th {{ background: #333; color: white; }}
.pass {{ background-color: #c8f7c5; }}
.fail {{ background-color: #f7c5c5; }}
</style>
</head>
<body>
<h1 align="center">UVM Regression Report</h1>
<p align="center">Generated : {now}</p>

<h2 align="center">Regression Summary</h2>
<table>
<tr>
<th>Test</th><th>Status</th><th>Total</th><th>Writes</th><th>Reads</th>
<th>SB Errors</th><th>UVM Errors</th><th>UVM Warnings</th>
</tr>
"""

for r in results:
    cls = "pass" if r["status"] == "PASS" else "fail"
    html += f"""
<tr class="{cls}">
<td>{r['test']}</td>
<td><b>{r['status']}</b></td>
<td>{r['total']}</td>
<td>{r['writes']}</td>
<td>{r['reads']}</td>
<td>{r['sb_errors']}</td>
<td>{r['uvm_errors']}</td>
<td>{r['uvm_warnings']}</td>
</tr>
"""

html += f"""
</table>

<h2 align="center">Overall Statistics</h2>
<table>
<tr>
<th>Total Tests</th><th>PASS</th><th>FAIL</th>
<th>Total Writes</th><th>Total Reads</th>
<th>Total SB Errors</th><th>Total UVM Errors</th><th>Total UVM Warnings</th>
</tr>
<tr>
<td>{total_tests}</td><td>{pass_tests}</td><td>{fail_tests}</td>
<td>{total_writes}</td><td>{total_reads}</td>
<td>{total_sb_err}</td><td>{total_uvm_err}</td><td>{total_uvm_warn}</td>
</tr>
</table>
</body>
</html>
"""

with open(HTML_OUT, "w") as f:
    f.write(html)

print("====================================")
print(" UVM Regression report generated")
print("====================================")
print(f"HTML : {HTML_OUT}")
print(f"CSV  : {CSV_OUT}")
print()
print(f"Tests      : {total_tests}")
print(f"PASS       : {pass_tests}")
print(f"FAIL       : {fail_tests}")
print()
print(f"Writes     : {total_writes}")
print(f"Reads      : {total_reads}")
print(f"SB Errors  : {total_sb_err}")
print(f"UVM Errors : {total_uvm_err}")
print(f"UVM Warns  : {total_uvm_warn}")
print()
