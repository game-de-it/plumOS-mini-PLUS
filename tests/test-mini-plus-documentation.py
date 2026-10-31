#!/usr/bin/env python3
"""Check bilingual guide coverage, local links and public README image metadata."""
from __future__ import annotations

import re
import struct
import subprocess
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
USER_TOPICS = (
    "README install operation storage supported-systems emulators apps save-data "
    "scraping network updates troubleshooting"
).split()
DEVELOPER_TOPICS = (
    "README architecture build runtime frontend-emulators audio-routing "
    "hardware-services storage-and-updates validation apps libretro-cores "
    "network-services manual-updates release-process"
).split()


def require(path: str, *needles: str) -> str:
    target = ROOT / path
    assert target.is_file(), f"missing documentation: {path}"
    text = target.read_text(encoding="utf-8")
    for needle in needles:
        assert needle in text, f"{path}: missing {needle!r}"
    return text


def check_links(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", text)
    links += re.findall(r'(?:src|href)="([^"]+)"', text)
    for raw in links:
        link = unquote(raw.split("#", 1)[0])
        if not link or "://" in link or link.startswith("mailto:"):
            continue
        target = (path.parent / link).resolve()
        assert target.exists(), f"{path.relative_to(ROOT)}: broken link {raw}"


def check_images() -> None:
    images = ROOT / "docs/images"
    for name in ("frontend-text.png", "frontend-graphics.png",
                 "frontend-graphics-list.png", "frontend-gallery.png"):
        data = (images / name).read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n"
        assert struct.unpack(">II", data[16:24]) == (640, 480), name

    data = (images / "gkd-mini-plus.jpg").read_bytes()
    assert data[:2] == b"\xff\xd8"
    pos = 2
    saw_frame = False
    # Parse marker segments, not arbitrary entropy bytes, to detect metadata.
    while pos < len(data):
        assert data[pos] == 0xFF
        while data[pos] == 0xFF:
            pos += 1
        marker = data[pos]
        pos += 1
        if marker in (0xDA, 0xD9):
            break
        length = int.from_bytes(data[pos:pos + 2], "big")
        assert length >= 2 and pos + length <= len(data)
        payload = data[pos + 2:pos + length]
        assert marker not in (0xE1, 0xEA, 0xED, 0xFE), "private camera metadata"
        assert not (marker == 0xE2 and payload.startswith(b"MPF\0"))
        if marker in (0xC0, 0xC2):
            assert struct.unpack(">HH", payload[1:5]) == (2070, 2760)
            saw_frame = True
        pos += length
    assert saw_frame


def main() -> None:
    subprocess.run(
        ["python3", "scripts/generate-mini-plus-supported-systems-doc.py", "--check"],
        cwd=ROOT, check=True,
    )
    curated = [ROOT / name for name in ("README.md", "README.ja.md",
                                       "docs/README.md", "docs/README.ja.md")]
    for folder, topics in (("user", USER_TOPICS), ("developer", DEVELOPER_TOPICS)):
        actual = {p.name.removesuffix(".ja.md").removesuffix(".md")
                  for p in (ROOT / "docs" / folder).glob("*.md")}
        assert set(topics) <= actual
        for topic in actual:
            for suffix in (".md", ".ja.md"):
                path = ROOT / "docs" / folder / (topic + suffix)
                assert path.is_file(), f"missing language pair: {path}"
                curated.append(path)

    for stem in (
        "docs/plumos-mini-plus-runtime-update",
        "docs/plumos-implementation-checklist",
        "docs/validation/2026-10-31-mini-plus-runtime-limitations",
        "docs/validation/2026-10-31-mini-plus-documentation-audit",
        "docs/images/README",
    ):
        for suffix in (".md", ".ja.md"):
            path = ROOT / (stem + suffix)
            assert path.is_file(), path
            curated.append(path)

    for suffix in (".md", ".ja.md"):
        text = require("README" + suffix, "gkd-mini-plus.jpg", "frontend-text.png",
                       "frontend-graphics-list.png", "frontend-gallery.png")
        assert text.count("frontend-gallery.png") >= 1
        require("docs/user/emulators" + suffix, "SELECT", "START", "Quit RetroArch",
                "Take Screenshot", "/storage/Screenshots/", "/storage/Images/")
        for path in (ROOT / "docs/user").glob("*" + suffix):
            text = path.read_text()
            assert "Function 2 (top edge)" not in text
            assert "Function 2（本体上部）" not in text

    require("docs/user/emulators.md", "above-right of START", "unconfirmed")
    require("docs/user/emulators.ja.md", "START", "右上", "未確認")
    require("docs/user/supported-systems.md", "Supported systems (88)", "Nintendo 3DS")
    require("docs/user/supported-systems.ja.md", "対応システム（88件）", "3DS")
    for path in curated:
        check_links(path)
    check_images()
    print("miniplus_documentation=result-ok languages=2 topics=paired links=ok images=ok")


if __name__ == "__main__":
    main()
