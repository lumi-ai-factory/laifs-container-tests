#!/bin/env python3

import difflib
import json
from pathlib import Path
import urllib.request


def main():
    benches_dir = Path("benchmarks")

    print("Getting diffs...")
    for bench_dir in benches_dir.iterdir():
        source_file = bench_dir / "ext.json"
        diff_file = bench_dir / "ext.diff"
        old_diff = None
        new_diff = None

        if not source_file.exists():
            continue

        with open(source_file) as f:
            sources = json.load(f)

        if diff_file.exists():
            with open(diff_file) as f:
                old_diff = f.read()

        with open(diff_file, "w"):
            # Erase file contents
            pass

        for local, remote in sources.items():
            with open(bench_dir / local) as f:
                lines_local = f.read().splitlines(keepends=True)
            with urllib.request.urlopen(remote) as f:
                lines_remote = f.read().decode("utf-8").splitlines(keepends=True)

            lines_diff = list(
                difflib.unified_diff(
                    lines_remote, lines_local, fromfile=remote, tofile=local
                )
            )

            with open(diff_file, "a") as f:
                f.writelines(lines_diff)

        if old_diff is not None:
            with open(diff_file) as f:
                new_diff = f.read()
            if old_diff != new_diff:
                print("Updated:", diff_file)
            else:
                print("Unchanged:", diff_file)
        else:
            print("Created:", diff_file)

    print("Done!")

if __name__ == "__main__":
    main()
