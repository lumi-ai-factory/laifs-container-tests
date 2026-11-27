#!/usr/bin/env python3
#
# Merge unframe reports from several allocations into one report.
#
# Usage: merge_reports.py <report directory> <test name> [<test name> ...]
#
# Each *.md file in the report directory starts with a "Nodes: ..." line,
# followed by unframe's output. The tests are printed in the given order, with
# the nodes of their allocation under each test's heading.

import sys
from pathlib import Path

blocks = {}
for report in sorted(Path(sys.argv[1]).glob("*.md")):
    lines = report.read_text().splitlines()
    nodes = lines[0] if lines and lines[0].startswith("Nodes:") else "Nodes: unknown"
    name = None
    for line in lines[1:]:
        if line.startswith("## "):
            name = line[3:].split(" (")[0]
            blocks[name] = [line, "", nodes]
        elif name:
            blocks[name].append(line)

for name in sys.argv[2:]:
    block = blocks.get(name, [f"## {name}", "", "No results, see the error output of the test run"])
    print()
    print("\n".join(block).rstrip())
