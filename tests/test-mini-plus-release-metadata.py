#!/usr/bin/env python3
"""Check version propagation and lossless per-component license export."""
from __future__ import annotations

import hashlib
import importlib.util
import os
import shutil
import subprocess
import tempfile
from zipfile import ZipFile
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

    seven_zip = shutil.which("7zz") or shutil.which("7z")
    if seven_zip:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scripts = root / "scripts"
            scripts.mkdir()
            for name in ("prepare-mini-plus-release.sh", "export-mini-plus-release-licenses.py"):
                shutil.copy2(ROOT / "scripts" / name, scripts / name)
            (root / "VERSION").write_text("0.1.0\n")
            (root / ".gitignore").write_text("output/\ndist/\nwork/\n")
            for name in ("LICENSE", "THIRD_PARTY_NOTICES.md"):
                (root / name).write_text("test fixture license\n")
            notes = root / "docs/releases/0.1.0.md"
            notes.parent.mkdir(parents=True)
            notes.write_text("English / 日本語 fixture\n")
            image = root / "output/image/mini-plus-frontend-probe/plumOS-mini-PLUS-0.1.0-full-stack-validation.img"
            image.parent.mkdir(parents=True)
            image.write_bytes(b"not a real device image; packaging fixture only\n")
            digest = hashlib.sha256(image.read_bytes()).hexdigest()
            (image.parent / "image.manifest").write_text(
                f"image_sha256={digest}\nsource_ref=fixture\npublishable=no\n")
            verified = root / "work/mini-plus-frontend-probe-verify"
            runtime = verified / "app-layer/plumos"
            system = verified / "system-root"
            (runtime / "licenses").mkdir(parents=True)
            (runtime / "VERSION").write_text("0.1.0\n")
            (runtime / "licenses/core-LICENSE").write_text("core fixture\n")
            (system / "usr/share/licenses").mkdir(parents=True)
            (system / "usr/share/licenses/NOTICE").write_text("system fixture\n")
            (system / "etc").mkdir()
            (system / "etc/os-release").write_text('VERSION_ID="0.1.0"\n')
            verifier = scripts / "verify-mini-plus-frontend-probe-image.sh"
            verifier.write_text("#!/bin/sh\nexit 0\n")
            verifier.chmod(0o755)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Fixture",
                            "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], check=True)
            command = ["bash", str(scripts / "prepare-mini-plus-release.sh")]
            env = dict(os.environ, SEVEN_ZIP=seven_zip, PLUMOS_MINI_PLUS_RELEASE_DRAFT="0")
            rejected = subprocess.run(command, env=env, capture_output=True)
            assert rejected.returncode == 2 and b"acceptance manifest" in rejected.stderr
            env["PLUMOS_MINI_PLUS_RELEASE_DRAFT"] = "1"
            subprocess.run(command, env=env, check=True, capture_output=True)
            bundle = root / "dist/plumos-mini-plus-release-v0.1.0-draft"
            manifest = (bundle / "manifest.txt").read_text()
            assert "draft=1" in manifest
            assert "physical_cold_boots=not-recorded" in manifest
            assert "host-verified-draft-not-device-accepted" in manifest
            assert "licenses/runtime/" not in (bundle / "SHA256SUMS").read_text()
            assert (bundle / "licenses/runtime/core-LICENSE").read_text() == "core fixture\n"
            with ZipFile(bundle / "plumos-mini-plus-v0.1.0-licenses.zip") as archive:
                assert archive.testzip() is None
                assert archive.read("licenses/runtime/core-LICENSE") == b"core fixture\n"
            subprocess.run(["shasum", "-a", "256", "-c", "SHA256SUMS"],
                           cwd=bundle, check=True, capture_output=True)
            publication = root / "docs/validation/0.1.0-mini-plus-device-acceptance.env"
            publication.parent.mkdir(parents=True)
            publication.write_text(
                "format=plumos-mini-plus-publication-with-recorded-limits-v1\n"
                f"image_sha256={digest}\nrelease_approved=yes\n"
                "new_image_device_acceptance=no\nphysical_cold_boots=not-recorded\n")
            subprocess.run(["git", "-C", str(root), "add", "docs"], check=True)
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Fixture",
                            "-c", "user.email=fixture@example.invalid", "commit", "-qm", "limits fixture"], check=True)
            env.update(PLUMOS_MINI_PLUS_RELEASE_DRAFT="0", PLUMOS_MINI_PLUS_RELEASE_RECORDED_LIMITS="1")
            subprocess.run(command, env=env, check=True, capture_output=True)
            published = root / "dist/plumos-mini-plus-release-v0.1.0/manifest.txt"
            manifest = published.read_text()
            assert "draft=0" in manifest and "new_image_device_acceptance=no" in manifest
            assert "physical_cold_boots=3" not in manifest

    notes = (ROOT / "docs/releases/0.1.0.md").read_text()
    for label in ("## 日本語", "## English", "MIT", "Raspberry Pi Imager",
                  "plumos-mini-plus-v0.1.0-sd-image.img", "plumos-mini-plus-v0.1.0-licenses.zip"):
        assert label in notes
    print("miniplus_release_metadata=result-ok version=0.1.0 propagation=ok license_originals=preserved languages=2")


if __name__ == "__main__":
    main()
