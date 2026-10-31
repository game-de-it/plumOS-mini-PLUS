#!/usr/bin/env python3
"""Signed System staging, trial selection, health commit and failure recovery."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
if len(sys.argv)<2 or sys.argv[1]!="--inside":
    raise SystemExit(subprocess.call(["docker","run","--rm","--platform","linux/arm64",
      "-v",str(ROOT)+":/work:ro","-w","/work",os.environ.get("PLUMOS_MINI_PLUS_TOOLS_IMAGE","plumos-mini-plus-tools:dev"),
      "python3","tests/test-mini-plus-system-ab.py","--inside"]))

BUILDER=ROOT/"scripts/build-mini-plus-update-package.py"
UPDATER=ROOT/"package/frontend-mini-plus/plumos/share/update/plumos-system-update.py"
SELECTOR=ROOT/"rootfs/mini-plus-external-initramfs/usr/sbin/plumos-mini-plus-system-slot"
BOOT_ID=Path("/proc/sys/kernel/random/boot_id").read_text().strip()

def run(cmd,env=None,expected_error=None):
    r=subprocess.run([str(s) for s in cmd],env=env,text=True,capture_output=True)
    if expected_error:
        assert r.returncode and expected_error in r.stderr,(cmd,r.stdout,r.stderr)
    else: assert r.returncode==0,(cmd,r.stdout,r.stderr)
    return r.stdout.strip()

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

with tempfile.TemporaryDirectory(prefix="mini-plus-system-ab-") as temp:
    work=Path(temp); boot=work/"flash/System"; boot.mkdir(parents=True)
    installed=work/"installed"; installed.mkdir()
    state=installed/"state/system-ab"; state.mkdir(parents=True)
    user=work/"user"; inbox=user/"updates"; inbox.mkdir(parents=True)
    for name,value in {"VERSION":"1.0.0","RUNTIME_ABI":"1","COMPAT_VENDOR":"mini-plus-stockos-r1"}.items():
        (installed/name).write_text(value+"\n")
    (user/"keep-save.srm").write_bytes(b"user save remains")
    (work/"abi").write_text("1\n")
    key=work/"private.pem"; public=work/"public.pem"
    run(["openssl","genpkey","-algorithm","ED25519","-out",key])
    run(["openssl","pkey","-in",key,"-pubout","-out",public])
    env=dict(os.environ,PLUMOS_ROOT=str(installed),PLUMOS_USERDATA_ROOT=str(user),
      PLUMOS_BOOT_ROOT=str(boot.parent),PLUMOS_UPDATE_PUBLIC_KEY=str(public),
      PLUMOS_SYSTEM_ABI_FILE=str(work/"abi"),PLUMOS_UPDATE_OPENSSL="openssl",
      PLUMOS_UPDATE_LOCK_FILE=str(work/"lock"),PLUMOS_UPDATE_PROGRESS="0")
    def image(version):
        tree=work/("tree-"+version); tree.mkdir(); (tree/"init").write_text("System fixture "+version)
        out=work/(version+".squashfs")
        run(["mksquashfs",tree,out,"-noappend","-no-progress","-processors","1"])
        return out
    old=image("1.0.0"); new=image("1.1.0"); newer=image("1.2.0"); older=image("0.9.0")
    def restore(slot,source,version):
        shutil.copy2(source,boot/f"system-{slot}.squashfs")
        (boot/f"system-{slot}.sha256").write_text(digest(source)+"\n")
        (boot/f"system-{slot}.version").write_text(version+"\n")
    restore("a",old,"1.0.0"); restore("b",old,"1.0.0")
    (boot/"active-slot").write_text("a\n")
    def package(source,version,base):
        run([sys.executable,BUILDER,"--type","system","--input",source,"--version",version,
             "--base-version",base,"--signing-key",key,"--output-dir",inbox])
        return inbox/f"plumos-mini-plus-system-{version}.tar.gz"
    p11=package(new,"1.1.0","1.0.0")
    p12=package(newer,"1.2.0","1.1.0")
    p09=package(older,"0.9.0","1.1.0")
    def update(*args,expected_error=None):
        return run([sys.executable,UPDATER,*args],env,expected_error)
    def select(boot_id=BOOT_ID,expected_error=None):
        return run(["sh",SELECTOR],dict(env,PLUMOS_SLOT_BOOT_ROOT=str(boot.parent),
              PLUMOS_SLOT_STATE_ROOT=str(state),PLUMOS_SLOT_BOOT_ID=boot_id),expected_error)
    update("request",p11,expected_error="unsupported by installed initramfs")
    assert digest(boot/"system-a.squashfs")==digest(old)
    (boot/"slot-policy").write_text("trial-v1\n")
    assert select()=="a"
    (boot/"active-slot").write_text("b\n")
    update("request",p11,expected_error="System health is not confirmed")
    assert digest(boot/"system-a.squashfs")==digest(old)
    (boot/"active-slot").write_text("a\n")
    update("request",p11)
    assert (boot/"active-slot").read_text().strip()=="a" and (boot/"pending-slot").read_text().strip()=="b"
    assert digest(boot/"system-a.squashfs")==digest(old)
    update("mark-healthy") # A future trial cannot be accepted/rejected in the old boot.
    assert (boot/"pending-slot").exists()
    assert select()=="b"
    update("mark-healthy")
    assert (boot/"active-slot").read_text().strip()=="b" and not (boot/"pending-slot").exists()
    assert not (state/"blocked-b.sha256").exists()
    assert json.loads((installed/"update-state/last-result.json").read_text())["result"]=="system_healthy"
    update("request",p09,expected_error="system downgrade is forbidden")
    update("request",p12)
    assert select("unsuccessful-boot")=="a"
    assert select()=="b"
    update("mark-healthy")
    assert not (boot/"pending-slot").exists() and (boot/"active-slot").read_text().strip()=="b"
    assert json.loads((installed/"update-state/last-result.json").read_text())["result"]=="system_rolled_back"
    # The failed image is hash-valid but must not be reused as an automatic fallback.
    (boot/"system-b.squashfs").write_bytes(b"broken-active")
    select(expected_error="no-healthy-system-slot")
    restore("b",new,"1.1.0")
    update("request",p12)
    (boot/"system-a.squashfs").write_bytes(b"broken-pending")
    assert select()=="b"
    update("mark-healthy")
    assert not (boot/"pending-slot").exists()
    # A corrupt unused slot must not block a healthy active System.
    assert select()=="b"
    # A valid known-good alternate can recover an invalid active slot.
    restore("a",old,"1.0.0")
    (boot/"system-b.squashfs").write_bytes(b"broken-active")
    assert select()=="a"
    update("mark-healthy")
    assert (boot/"active-slot").read_text().strip()=="a"
    (boot/"system-a.squashfs").write_bytes(b"broken-both")
    select(expected_error="no-healthy-system-slot")
    assert (installed/"VERSION").read_text().strip()=="1.0.0"
    assert (user/"keep-save.srm").read_bytes()==b"user save remains"
    print("miniplus_system_ab=result-ok inactive_readback=yes health_commit=yes failed_trial_rollback=yes invalid_pending_recovery=yes inactive_corruption_tolerated=yes known_bad_fallback_rejected=yes both_bad_rejected=yes persistence=yes")
