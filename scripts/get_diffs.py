#!/bin/env python3

import difflib
import json
from pathlib import Path
import urllib.request


def main():
    benches_dir = Path("benchmarks")

    for bench_dir in benches_dir.iterdir():
        source_file = bench_dir / "sources.json"
        diff_file = bench_dir / "diff.txt"

        if not source_file.exists():
            continue
        with open(source_file) as f:
            sources = json.load(f)

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


if __name__ == "__main__":
    main()
