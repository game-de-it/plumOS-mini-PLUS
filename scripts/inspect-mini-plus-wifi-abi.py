#!/usr/bin/env python3
"""Verify the captured mini PLUS kernel/module contract used by Wi-Fi trials."""

from __future__ import annotations

import gzip
import hashlib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
KERNEL = ROOT / "artifacts/vendor/mini-plus-stock-source/boot/Image"
MODULE = ROOT / "artifacts/vendor/mini-plus-stock-source/runtime/modules/8821cs.ko"
KERNEL_SHA256 = "670c32a86cf006a574d5ec498df6c14e3ac61af6ed6b109f458b5711c228da56"
MODULE_SHA256 = "873392f49ce6f1ca8acc501fb7d80367ef7cc54dbfebe9b0c8c531ac06f81037"
KERNEL_VERMAGIC = (
    b"4.19.193-g5a07852a55cf-dirty SMP mod_unload modversions aarch64"
)
MODULE_VERMAGIC = b"vermagic=4.19.172 SMP mod_unload aarch64"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def embedded_config(image: bytes) -> str:
    start = image.index(b"IKCFG_ST") + len(b"IKCFG_ST")
    end = image.index(b"IKCFG_ED", start)
    return gzip.decompress(image[start:end]).decode("utf-8")


def main() -> None:
    assert KERNEL.is_file(), f"missing captured kernel: {KERNEL}"
    assert MODULE.is_file(), f"missing captured Wi-Fi module: {MODULE}"
    assert sha256(KERNEL) == KERNEL_SHA256, "captured kernel hash mismatch"
    assert sha256(MODULE) == MODULE_SHA256, "captured Wi-Fi module hash mismatch"

    image = KERNEL.read_bytes()
    module = MODULE.read_bytes()
    assert KERNEL_VERMAGIC in image, "running-kernel vermagic not found"
    assert MODULE_VERMAGIC in module, "stock module vermagic not found"

    config = embedded_config(image)
    for setting in (
        "CONFIG_IKCONFIG=y",
        "CONFIG_MODULES=y",
        "CONFIG_MODULE_FORCE_LOAD=y",
        "CONFIG_MODVERSIONS=y",
        "CONFIG_CFG80211=y",
        "CONFIG_MMC=y",
    ):
        assert setting in config.splitlines(), f"kernel setting missing: {setting}"

    assert b"__versions\0" not in module, "module unexpectedly contains symbol CRCs"

    print(
        "miniplus_wifi_abi=result-ok "
        "kernel_modversions=yes module_symbol_crcs=no "
        "kernel_force_load=yes policy=normal-then-explicit-force"
    )


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, ValueError) as error:
        print(f"miniplus_wifi_abi=result-fail reason={error}", file=sys.stderr)
        raise SystemExit(1)
