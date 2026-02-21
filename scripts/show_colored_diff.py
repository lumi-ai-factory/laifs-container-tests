#!/bin/env python3

import json
import re
import sys


def main(input_dir):
    with open(input_dir + "/sources.json") as f:
        sources = json.load(f)

    with open(input_dir + "/diff.txt") as f:
        lines_old = f.readlines()

    lines_new = []

    for line in lines_old:
        for local, remote in sources.items():
            # Filenames in bold
            line = re.sub(fr"^(---{remote})$", "\033[1m" + r"\1" + "\033[0m", line)
            line = re.sub(fr"^(\+\+\+{local})$", "\033[1m" + r"\1" + "\033[0m", line)

        # Context in cyan
        line = re.sub(
            r"^(@@\s-\d+,\d+\s\+\d+,\d+\s@@)", "\033[36m" + r"\1" + "\033[0m", line
        )

        # Old in red
        line = re.sub(r"^(-.*)$", "\033[31m" + r"\1" + "\033[0m", line)
        # New in green
        line = re.sub(r"^(\+.*)$", "\033[32m" + r"\1" + "\033[0m", line)

        lines_new.append(line)

    print("".join(lines_new), end="")


if __name__ == "__main__":
    main(sys.argv[1])
