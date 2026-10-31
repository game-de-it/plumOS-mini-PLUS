#!/usr/bin/env python3
"""Export original notices and a bilingual index from verified image readback."""
from __future__ import annotations

import argparse
import hashlib
import shutil
from pathlib import Path
from urllib.parse import quote


def export(runtime: Path, system: Path, output: Path) -> int:
    sources = {"runtime": runtime, "system": system}
    for name, source in sources.items():
        if not source.is_dir() or not any(source.rglob("*")):
            raise ValueError(f"missing {name} license originals: {source}")
        if any(p.is_symlink() for p in source.rglob("*")):
            raise ValueError(f"unexpected symlink in {name} license originals")
    if output.exists():
        raise ValueError(f"output already exists: {output}")
    output.mkdir(parents=True)
    records = []
    for name, source in sources.items():
        shutil.copytree(source, output / name)
        for path in sorted((output / name).rglob("*")):
            if path.is_file():
                relative = path.relative_to(output).as_posix()
                digest = hashlib.sha256(path.read_bytes()).hexdigest()
                records.append((relative, digest))
    header = (
        "# Licenses / ライセンス\n\n"
        "plumOS-authored code and documentation: **MIT**, see ../LICENSE. "
        "Third-party software retains its own terms; it is not relicensed as MIT. "
        "Each link below opens the original notice copied from the verified SD image. "
        "See ../THIRD_PARTY_NOTICES.md for GKD/vendor and DraStic boundaries.\n\n"
        "plumOS独自のコード・文書は**MIT**です（../LICENSE）。同梱の第三者ソフトは"
        "それぞれのライセンスに従い、MITへ変更しません。以下は検証済みSDイメージから"
        "取り出した原文です。GKD/vendor・DraSticの区分は../THIRD_PARTY_NOTICES.mdを"
        "参照してください。ファイル名で対象componentを確認できます。\n\n"
        "| Component notice / component別原文 | Image area / 収録領域 |\n"
        "| --- | --- |\n"
    )
    rows = [f"| [{Path(name).name}]({quote(name)}) | {name.split('/')[0]} |"
            for name, _ in records]
    (output / "README.md").write_text(header + "\n".join(rows) + "\n", encoding="utf-8")
    (output / "SHA256SUMS").write_text(
        "".join(f"{digest}  {name}\n" for name, digest in records), encoding="utf-8")
    return len(records)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-licenses", type=Path, required=True)
    parser.add_argument("--system-licenses", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    count = export(args.runtime_licenses, args.system_licenses, args.output)
    print(f"miniplus_release_licenses=result-ok originals={count} index_languages=2")


if __name__ == "__main__":
    main()
