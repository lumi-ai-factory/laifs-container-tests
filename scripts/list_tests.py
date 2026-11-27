#!/usr/bin/env python3
#
# List the unframe tests that have a tag, in the order unframe runs them.
#
# Usage: list_tests.py <tests directory> <tag>
#
# Prints "<name> <nodes>" for each test. Nodes come from --nodes or -N in the
# test's job, and are 0 if the job doesn't set them.

import re
import sys
import yaml
from pathlib import Path

for p in sorted(Path(sys.argv[1]).glob("*.yaml")):
    try:
        spec = yaml.safe_load(p.read_text())
    except Exception:
        continue
    if sys.argv[2] not in spec.get("tags", []):
        continue
    m = re.search(r"(?:--nodes[= ]|-N ?)(\d+)", " ".join(map(str, spec.get("job", []))))
    print(spec["name"], m.group(1) if m else 0)
