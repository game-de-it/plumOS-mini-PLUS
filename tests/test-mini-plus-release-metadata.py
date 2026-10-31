#!/usr/bin/env python3
"""Check version propagation and lossless per-component license export."""
from __future__ import annotations

import hashlib
import importlib.util
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "license_export", ROOT / "scripts/export-mini-plus-release-licenses.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        runtime, system = root / "runtime", root / "system"
        runtime.mkdir()
        (system / "debian").mkdir(parents=True)
        (runtime / "core-LICENSE").write_bytes(b"core license\r\nkept verbatim\n")
        (system / "debian/copyright").write_text("separate System terms\n")
        output = root / "export"
        assert module.export(runtime, system, output) == 2
        index = (output / "README.md").read_text()
        assert "MIT" in index and "ライセンス" in index
        for relative in ("runtime/core-LICENSE", "system/debian/copyright"):
            data = (output / relative).read_bytes()
            assert data == (root / relative).read_bytes()
            assert f"]({relative})" in index
            assert hashlib.sha256(data).hexdigest() in (output / "SHA256SUMS").read_text()
        try:
            module.export(runtime, system, output)
        except ValueError:
            pass
        else:
            raise AssertionError("must not overwrite an existing license bundle")

        scripts = root / "scripts"
        scripts.mkdir()
        wrapper = scripts / "build-mini-plus-full-image.sh"
        wrapper.write_bytes((ROOT / "scripts/build-mini-plus-full-image.sh").read_bytes())
        (root / "VERSION").write_bytes((ROOT / "VERSION").read_bytes())
        child = scripts / "build-mini-plus-frontend-probe-image.sh"
        child.write_text('#!/bin/sh\nprintf "%s\\n" "$PLUMOS_MINI_PLUS_VERSION"\n')
        child.chmod(0o755)
        env = dict(os.environ)
        env.pop("PLUMOS_MINI_PLUS_VERSION", None)
        assert subprocess.check_output(["sh", str(wrapper)], env=env, stderr=subprocess.DEVNULL).strip() == b"0.1.0"
        env["PLUMOS_MINI_PLUS_VERSION"] = "0.1.1-dev"
        assert subprocess.check_output(["sh", str(wrapper)], env=env, stderr=subprocess.DEVNULL).strip() == b"0.1.1-dev"

    notes = (ROOT / "docs/releases/0.1.0.md").read_text()
    for label in ("## 日本語", "## English", "MIT", "LGPL-2.1-only",
                  "plumos-mini-plus-v0.1.0-sd-image.img", "licenses/README.md"):
        assert label in notes
    print("miniplus_release_metadata=result-ok version=0.1.0 propagation=ok license_originals=preserved languages=2")


if __name__ == "__main__":
    main()
