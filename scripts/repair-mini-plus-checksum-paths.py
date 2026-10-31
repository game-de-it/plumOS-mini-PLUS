#!/usr/bin/env python3
"""Recover truncated checksum filenames without changing any recorded hash.

Use a known clean package checksum as a path dictionary only. A repair requires
the old recorded digest and the truncated filename prefix to identify exactly
one complete path. Settings, live binaries, and their hashes are never rebased.
"""

import argparse
from collections import Counter
import json
from pathlib import Path, PurePosixPath
import re


def entries(text):
    result = []
    for line in text.splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if not match:
            raise ValueError("invalid SHA-256 line")
        digest, path = match.groups()
        if PurePosixPath(path).is_absolute() or ".." in PurePosixPath(path).parts:
            raise ValueError("unsafe checksum path")
        result.append((digest, path))
    return result


def repair(original, reference):
    original_entries = entries(original)
    by_digest = {}
    for digest, path in entries(reference):
        by_digest.setdefault(digest, set()).add(path)
    repaired = []
    changes = []
    counts = Counter(original_entries)
    assigned = {}
    for digest, path in original_entries:
        candidates = by_digest.get(digest, set())
        if path not in candidates:
            matches = sorted(p for p in candidates if p.startswith(path + " "))
            if matches:
                # Identical icon contents can share a digest and a truncated
                # first word. Recover only when the entire multiset is known.
                key = (digest, path)
                matches = [p for p in matches if (digest, p) not in counts]
                if len(matches) != counts[key]:
                    raise ValueError(f"ambiguous truncated path: {path}")
                index = assigned.get(key, 0)
                restored = matches[index]
                assigned[key] = index + 1
                changes.append({"before": path, "after": restored})
                path = restored
        repaired.append(f"{digest}  {path}\n")
    return "".join(repaired), changes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("original", type=Path)
    parser.add_argument("reference", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    result, changes = repair(args.original.read_text(), args.reference.read_text())
    with args.output.open("x") as stream:
        stream.write(result)
    print(json.dumps({"repaired_paths": len(changes), "hashes_changed": 0,
                      "entries": len(entries(result))}))


if __name__ == "__main__":
    main()
