#!/usr/bin/env python3
"""Save-isolated machine checks; does not certify physical display or controls."""
import importlib.util
import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
import re

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "matrix", ROOT / "scripts/run-mini-plus-emulator-device-matrix.py")
matrix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(matrix)


def run(script, *args, check=True):
    result = subprocess.run(
        ["sshpass", "-e", "ssh", "-o", "StrictHostKeyChecking=no",
         "-o", "ConnectTimeout=8", "root@192.168.10.141",
         "sh -s -- " + " ".join(shlex.quote(a) for a in args)],
        input=script, text=True, capture_output=True, timeout=100)
    if check and result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    return result


def analyse_samples(profile, read):
    result = {}
    for phase in ("before", "after"):
        drm = read(f"{profile}.{phase}.drm")
        active = re.findall(r"^plane id=(\d+) crtc_id=([1-9]\d*) fb_id=([1-9]\d*)", drm, re.M)
        geometry = {}
        for plane, crtc, fb in active:
            props = dict(re.findall(
                rf"^property object=plane object_id={plane} property_id=\d+ name=(\w+) value=(\d+)",
                drm, re.M))
            geometry[plane] = {key: int(props[key]) for key in
                               ("CRTC_X", "CRTC_Y", "CRTC_W", "CRTC_H", "SRC_X", "SRC_Y", "SRC_W", "SRC_H")}
        audio = [read(f"{profile}.{phase}.audio{i}") for i in (1, 2)]
        hw = [re.search(r"^hw_ptr\s*:\s*(\d+)", a, re.M) for a in audio]
        progress = all("state: RUNNING" in a for a in audio) and all(hw) and hw[0][1] != hw[1][1]
        result[phase] = {"active_planes": active, "geometry": geometry,
                         "pcm_progress": bool(progress)}
    result["pass"] = bool(result["before"]["geometry"]) and all(
        result[p]["pcm_progress"] for p in ("before", "after")) and (
        result["before"]["geometry"] == result["after"]["geometry"])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--analyse-directory", type=Path)
    args = parser.parse_args()
    if args.analyse_directory:
        results = {}
        for profile in ("ra", "pico", "gles", "standalone"):
            results[profile] = analyse_samples(
                profile, lambda name: (args.analyse_directory / name).read_text())
        print(json.dumps(results, indent=2))
        if not all(row["pass"] for row in results.values()):
            raise SystemExit(1)
        return
    if not os.environ.get("SSHPASS"):
        raise SystemExit("set SSHPASS before running")
    run("test ! -s /run/plumos/frontend/foreground.pgid\n")
    paths = {
        "ra": "gb/Baseball.gb",
        "pico": "gb/Baseball.gb",
        "gles": "n64/AeroGauge [V1.1].z64",
        "standalone": "psp/Telegraph Crosswords.cso",
    }
    report = []
    try:
        run(matrix.SETUP, "maintenance-20261031")
        for profile, relative in paths.items():
            content = "/storage/plumos/state/device-matrix/content/rom2-20260904/" + relative
            result = run('/bin/busybox sh /tmp/check-mini-plus-sleep-device.sh "$1" "$2"\n',
                         profile, content, check=False)
            row = {"profile": profile, "exit": result.returncode,
                   "stdout": result.stdout, "stderr": result.stderr}
            if not result.returncode:
                prefix = "/storage/plumos/state/device-matrix/maintenance-20261031/"
                row["samples"] = analyse_samples(
                    profile, lambda name: run("cat " + shlex.quote(prefix + name) + "\n").stdout)
                if not row["samples"]["pass"]:
                    row["exit"] = 1
            report.append(row)
            print(json.dumps(row), flush=True)
            if result.returncode:
                break
    finally:
        print(run(matrix.TEARDOWN, check=False).stdout, flush=True)
    if any(row["exit"] for row in report):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
