#!/usr/bin/env python3
"""Instrument the captured mini PLUS boot.cmd with console-only U-Boot stages."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
from pathlib import Path

EXPECTED_BOOT_CMD_SHA256 = "c745d2469aa1a25617c49bb2b8bde9b8788efcc4f4bd2300f88a38bd12df2697"


def load_image_builder():
    module_path = Path(__file__).with_name("mkimage-uboot-script.py")
    spec = importlib.util.spec_from_file_location("mkimage_uboot_script", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.build_image


def marker(stage: str) -> str:
    if len(stage) != 3 or stage[0] not in "SE" or not stage[1:].isdigit():
        raise ValueError(f"invalid U-Boot stage {stage!r}")
    return f'echo "[plumOS mini PLUS probe] {stage}"\n'


def replace_once(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f"expected one anchor, found {count}: {old!r}")
    return text.replace(old, new, 1)


def instrument(source: str, external_initramfs: bool = True) -> str:
    result = replace_once(
        source,
        'setenv load_addr "0x02000000"\n',
        'setenv load_addr "0x02000000"\n' + marker("S10"),
    )
    result = replace_once(
        result,
        "\tenv import -t ${load_addr} ${filesize}\nfi\n",
        "\tenv import -t ${load_addr} ${filesize}\nfi\n" + marker("S11"),
    )
    if not external_initramfs:
        raise ValueError("GKD mini PLUS requires its external initramfs boot path")
    result = replace_once(
        result,
        "load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${initrdimg}\n",
        "if load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${initrdimg}; then\n"
        "\tsetenv initrdsize ${filesize}\n"
        + marker("S12")
        + "else\n"
        + marker("E12")
        + "\texit\nfi\n",
    )
    kernel_success, kernel_failure = "S13", "E13"
    dtb_success, dtb_failure = "S14", "E14"
    handoff_stage = "S15"
    result = replace_once(
        result,
        "load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${kernelimg}\n",
        "if load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${kernelimg}; then\n"
        + marker(kernel_success)
        + "else\n"
        + marker(kernel_failure)
        + "\texit\nfi\n",
    )
    result = replace_once(
        result,
        "load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtbs/${kernelversion}/${fdtfile}\n"
        "fdt addr ${fdt_addr_r}\n",
        "if load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtbs/${kernelversion}/${fdtfile}; then\n"
        + marker(dtb_success)
        + "else\n"
        + marker(dtb_failure)
        + "\texit\nfi\n"
        + "fdt addr ${fdt_addr_r}\n",
    )
    result = replace_once(
        result,
        'echo "initrdsize = $initrdsize"\n',
        marker(handoff_stage) + 'echo "initrdsize = $initrdsize"\n' + marker("S19"),
    )
    result = replace_once(
        result,
        "booti ${kernel_addr_r} ${ramdisk_addr_r}:${initrdsize} ${fdt_addr_r}\n",
        "booti ${kernel_addr_r} ${ramdisk_addr_r}:${initrdsize} ${fdt_addr_r}\n"
        + marker("E20"),
    )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--external-initramfs", action="store_true", default=True)
    parser.add_argument("input", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    source_bytes = args.input.read_bytes()
    actual = hashlib.sha256(source_bytes).hexdigest()
    if actual != EXPECTED_BOOT_CMD_SHA256:
        raise SystemExit(f"refusing unknown boot.cmd: expected {EXPECTED_BOOT_CMD_SHA256}, got {actual}")
    instrumented = instrument(source_bytes.decode("utf-8"), args.external_initramfs)
    command = instrumented.encode("utf-8")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "boot.cmd").write_bytes(command)
    build_image = load_image_builder()
    (args.output_dir / "boot.scr").write_bytes(build_image(command, 0, "plumOS mini PLUS boot probe"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
