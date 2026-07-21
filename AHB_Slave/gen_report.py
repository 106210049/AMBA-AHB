#!/usr/bin/env python3

import os
import re
import glob
import csv
from datetime import datetime
from collections import Counter

# ==================================================
# Config
# ==================================================
LOG_DIR = "logs_test/*.log"
HTML_OUT = "report.html"
CSV_OUT  = "report.csv"

# ==================================================
# Regex
# ==================================================
RE_WRITES = re.compile(r"Writes\s*:\s*(\d+)")
RE_READS  = re.compile(r"Reads\s*:\s*(\d+)")
RE_ERRORS = re.compile(r"Errors\s*:\s*(\d+)")
RE_WARNS  = re.compile(r"Warnings\s*:\s*(\d+)")

RE_SB_FAIL = re.compile(r"\[SB-FAIL\]|\[SB-ERR\]")

RE_PASS  = re.compile(r"\[PASS\]")
RE_FAIL  = re.compile(r"\[FAIL\]")
RE_WARN  = re.compile(r"\[WARN\]")
RE_COVER = re.compile(r"\[COVER\]")

# Assertion fail message
RE_ASSERT_FAIL_NAME = re.compile(
    r"ASSERT_([A-Z0-9_]+).*?failed",
    re.MULTILINE
)

# ==================================================
# Parse log
# ==================================================
def parse_log(path):

    with open(path, "r", errors="ignore") as f:
        content = f.read()

    testname = os.path.basename(path).replace(".log", "")

    writes = 0
    reads = 0
    sb_errors = 0
    warns = 0

    m = RE_WRITES.search(content)
    if m:
        writes = int(m.group(1))

    m = RE_READS.search(content)
    if m:
        reads = int(m.group(1))

    m = RE_ERRORS.search(content)
    if m:
        sb_errors = int(m.group(1))

    m = RE_WARNS.search(content)
    if m:
        warns = int(m.group(1))

    sva_pass  = len(RE_PASS.findall(content))
    sva_fail  = len(RE_FAIL.findall(content))
    sva_warn  = len(RE_WARN.findall(content))
    cover_cnt = len(RE_COVER.findall(content))

    failed_asserts = Counter(
        RE_ASSERT_FAIL_NAME.findall(content)
    )

    status = "PASS"

    if (
        sb_errors > 0
        or sva_fail > 0
        or RE_SB_FAIL.search(content)
    ):
        status = "FAIL"

    return {
        "test": testname,
        "status": status,

        "writes": writes,
        "reads": reads,

        "sb_errors": sb_errors,
        "warnings": warns,

        "sva_pass": sva_pass,
        "sva_fail": sva_fail,
        "sva_warn": sva_warn,

        "cover": cover_cnt,

        "assertions": failed_asserts
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
# Global assertion statistics
# ==================================================
global_assertions = Counter()

for r in results:
    global_assertions.update(r["assertions"])

# ==================================================
# CSV Report
# ==================================================
with open(CSV_OUT, "w", newline="") as f:

    writer = csv.writer(f)

    writer.writerow([
        "Test",
        "Status",
        "Writes",
        "Reads",
        "SB Errors",
        "Warnings",
        "SVA Pass",
        "SVA Fail",
        "SVA Warn",
        "Cover"
    ])

    for r in results:

        writer.writerow([
            r["test"],
            r["status"],
            r["writes"],
            r["reads"],
            r["sb_errors"],
            r["warnings"],
            r["sva_pass"],
            r["sva_fail"],
            r["sva_warn"],
            r["cover"]
        ])

# ==================================================
# Statistics
# ==================================================
total_tests = len(results)
pass_tests = sum(1 for r in results if r["status"] == "PASS")
fail_tests = total_tests - pass_tests

total_sva_pass = sum(r["sva_pass"] for r in results)
total_sva_fail = sum(r["sva_fail"] for r in results)
total_sva_warn = sum(r["sva_warn"] for r in results)

now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# ==================================================
# HTML
# ==================================================
html = f"""
<html>

<head>

<title>AHB Regression Report</title>

<style>

body {{
    font-family: Arial;
    margin: 20px;
}}

table {{
    border-collapse: collapse;
    width: 90%;
    margin: auto;
    margin-bottom: 30px;
}}

th, td {{
    border: 1px solid #ccc;
    padding: 8px;
    text-align: center;
}}

th {{
    background: #333;
    color: white;
}}

.pass {{
    background-color: #c8f7c5;
}}

.fail {{
    background-color: #f7c5c5;
}}

.summary {{
    text-align: center;
}}

</style>

</head>

<body>

<h1 align="center">AHB Regression Report</h1>

<p align="center">
Generated : {now}
</p>

<h2 align="center">Regression Summary</h2>

<table>

<tr>
<th>Test</th>
<th>Status</th>
<th>Writes</th>
<th>Reads</th>
<th>SB Errors</th>
<th>Warnings</th>
</tr>
"""

# ==================================================
# Main Table
# ==================================================
for r in results:

    cls = "pass" if r["status"] == "PASS" else "fail"

    html += f"""
<tr class="{cls}">
<td>{r['test']}</td>
<td><b>{r['status']}</b></td>
<td>{r['writes']}</td>
<td>{r['reads']}</td>
<td>{r['sb_errors']}</td>
<td>{r['warnings']}</td>
</tr>
"""

html += """
</table>
"""

# ==================================================
# Assertion Analysis
# ==================================================
html += """
<h2 align="center">Assertion Analysis</h2>

<table>

<tr>
<th>Test</th>
<th>SVA PASS</th>
<th>SVA FAIL</th>
<th>SVA WARN</th>
<th>COVER</th>
</tr>
"""

for r in results:

    cls = "pass" if r["sva_fail"] == 0 else "fail"

    html += f"""
<tr class="{cls}">
<td>{r['test']}</td>
<td>{r['sva_pass']}</td>
<td>{r['sva_fail']}</td>
<td>{r['sva_warn']}</td>
<td>{r['cover']}</td>
</tr>
"""

html += """
</table>
"""

# ==================================================
# Failed Assertion Summary
# ==================================================
html += """
<h2 align="center">Failed Assertion Summary</h2>

<table>

<tr>
<th>Assertion</th>
<th>Fail Count</th>
</tr>
"""

if len(global_assertions) == 0:

    html += """
<tr class="pass">
<td colspan="2"><b>No Assertion Failure</b></td>
</tr>
"""

else:

    for name, cnt in global_assertions.most_common():

        html += f"""
<tr class="fail">
<td>ASSERT_{name}</td>
<td>{cnt}</td>
</tr>
"""

html += """
</table>
"""

# ==================================================
# Overall Statistics
# ==================================================
html += f"""
<h2 align="center">Overall Statistics</h2>

<table>

<tr>
<th>Total Tests</th>
<th>PASS</th>
<th>FAIL</th>
<th>Total SVA PASS</th>
<th>Total SVA FAIL</th>
<th>Total SVA WARN</th>
</tr>

<tr>
<td>{total_tests}</td>
<td>{pass_tests}</td>
<td>{fail_tests}</td>
<td>{total_sva_pass}</td>
<td>{total_sva_fail}</td>
<td>{total_sva_warn}</td>
</tr>

</table>

</body>
</html>
"""

# ==================================================
# Write HTML
# ==================================================
with open(HTML_OUT, "w") as f:
    f.write(html)

# ==================================================
# Done
# ==================================================
print()
print("====================================")
print(" Regression report generated")
print("====================================")
print(f"HTML : {HTML_OUT}")
print(f"CSV  : {CSV_OUT}")
print()

print(f"Tests      : {total_tests}")
print(f"PASS       : {pass_tests}")
print(f"FAIL       : {fail_tests}")
print()

print(f"SVA PASS   : {total_sva_pass}")
print(f"SVA FAIL   : {total_sva_fail}")
print(f"SVA WARN   : {total_sva_warn}")
print()