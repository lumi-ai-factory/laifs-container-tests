#!/bin/env python3

import difflib
import json
from pathlib import Path
import urllib.request


def main():
    p = Path("applications")

    for appdir in p.iterdir():
        matches = list(appdir.glob("sources.json"))
        if not matches:
            continue

        with open(matches[0]) as f:
            sources = json.load(f)

        with open(appdir / "diff.txt", "w"):
            # Erase file contents
            pass

        for local, remote in sources.items():
            with open(appdir / local) as f:
                lines_local = f.read().splitlines(keepends=True)
            with urllib.request.urlopen(remote) as f:
                lines_remote = f.read().decode("utf-8").splitlines(keepends=True)

            lines_diff = list(
                difflib.unified_diff(
                    lines_remote, lines_local, fromfile=remote, tofile=local
                )
            )

            with open(appdir / "diff.txt", "a") as f:
                f.writelines(lines_diff)


if __name__ == "__main__":
    main()
