"""Inactive System slot staging and frontend-ready commit, separate from Runtime."""
from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import subprocess

def boot_root():
    return Path(os.environ.get("PLUMOS_BOOT_ROOT", "/flash")) / "System"

def state_root(e):
    return e.PLUMOS_ROOT / "state/system-ab"

def capability(e):
    if e.read_text(boot_root()/"slot-policy") != "trial-v1":
        raise e.UpdateError("System A/B update unsupported by installed initramfs; use a compatible full SD image")

def active(e):
    slot=e.read_text(boot_root()/"active-slot")
    if slot not in {"a","b"}: raise e.UpdateError("invalid System active slot")
    return slot

def version(e):
    capability(e)
    return e.read_text(boot_root()/f"system-{active(e)}.version", "unknown")

@contextmanager
def writable_boot():
    # Fixtures are ordinary directories. Only a real mount point is remounted.
    mountpoint=boot_root().parent
    readonly=False
    for line in Path("/proc/mounts").read_text().splitlines() if Path("/proc/mounts").exists() else []:
        fields=line.split()
        if fields[1]==str(mountpoint) and "ro" in fields[3].split(","): readonly=True
    if readonly: subprocess.run(["mount","-o","remount,rw",str(mountpoint)],check=True)
    try:
        yield
    finally:
        os.sync()
        if readonly: subprocess.run(["mount","-o","remount,ro",str(mountpoint)],check=True)

def verified(e, slot):
    path=boot_root()/f"system-{slot}.squashfs"
    digest=e.read_text(boot_root()/f"system-{slot}.sha256").split()
    return bool(path.is_file() and digest and e.sha256_file(path)==digest[0])

def apply(e, package, manifest):
    capability(e)
    root=boot_root(); state=state_root(e)
    if (root/"pending-slot").exists(): raise e.UpdateError("a System trial is already pending")
    booted=e.read_text(state/"booted").split()
    boot_id=e.read_text(Path("/proc/sys/kernel/random/boot_id"))
    if booted != [active(e),boot_id]:
        raise e.UpdateError("System health is not confirmed for the active slot; reboot before updating")
    slot="b" if active(e)=="a" else "a"
    if not verified(e,active(e)): raise e.UpdateError("current System slot is not healthy")
    e.extract_payload(package,manifest,e.STAGING_ROOT)
    source=e.STAGING_ROOT/"system.squashfs"
    with source.open("rb") as handle:
        if handle.read(4)!=b"hsqs": raise e.UpdateError("System payload is not SquashFS")
    next_path=root/f"system-{slot}.squashfs.next"
    if shutil.disk_usage(root).free + (next_path.stat().st_size if next_path.exists() else 0) < source.stat().st_size+1048576:
        raise e.UpdateError("insufficient boot space for inactive System staging")
    digest=manifest["files"][0]["sha256"]
    state.mkdir(parents=True,exist_ok=True)
    # A signed but not-yet-booted image must not become an automatic fallback.
    e.atomic_bytes(state/f"blocked-{slot}.sha256",(digest+"\n").encode())
    with writable_boot():
        target=root/f"system-{slot}.squashfs"
        temp=root/f"system-{slot}.squashfs.next"
        with source.open("rb") as src, temp.open("wb") as dst:
            shutil.copyfileobj(src,dst,1024*1024); dst.flush(); e.fsync_file_descriptor(dst.fileno())
        # Read the written inactive image completely before any boot selection changes.
        if e.sha256_file(temp)!=digest: raise e.UpdateError("inactive System readback hash mismatch")
        os.replace(temp,target); e.fsync_directory(root)
        e.atomic_bytes(root/f"system-{slot}.sha256",f"{digest}  system-{slot}.squashfs\n".encode())
        e.atomic_bytes(root/f"system-{slot}.version",(manifest["version"]+"\n").encode())
        (state/f"trial-{slot}").unlink(missing_ok=True)
        e.atomic_json(state/"pending.json",{"slot":slot,"previous":active(e),"version":manifest["version"],"sha256":digest})
        # Selection is the final durable write; active-slot is retained until FE readiness.
        e.atomic_bytes(root/"pending-slot",(slot+"\n").encode())
    e.REQUEST_FILE.unlink(missing_ok=True)
    e.atomic_json(e.LAST_RESULT,{"result":"system_pending","slot":slot,"version":manifest["version"]})
    return 0

def mark_healthy(e):
    root=boot_root(); state=state_root(e)
    if e.read_text(root/"slot-policy")!="trial-v1": return
    booted=e.read_text(state/"booted").split()
    boot_id=e.read_text(Path("/proc/sys/kernel/random/boot_id"))
    if len(booted)!=2 or booted[0] not in {"a","b"} or booted[1]!=boot_id: return
    slot=booted[0]; pending=e.read_text(root/"pending-slot")
    if pending not in {"","a","b"}: raise e.UpdateError("invalid pending System slot")
    if not pending and active(e)==slot: return
    if pending and pending!=slot and pending!=active(e) and not (state/f"trial-{pending}").exists():
        # The System request may have just staged a future trial in this boot.
        if e.read_text(state/"rejected") != f"{pending} {boot_id}": return
    if not verified(e,slot): raise e.UpdateError("booted System slot readback failed")
    if pending and pending!=slot:
        result={"result":"system_rolled_back","rejected_slot":pending,"active_slot":slot}
    elif pending:
        result={"result":"system_healthy","active_slot":slot}
    elif active(e)!=slot:
        result={"result":"system_recovered","active_slot":slot}
    else:
        return
    with writable_boot():
        e.atomic_bytes(root/"active-slot",(slot+"\n").encode())
        (root/"pending-slot").unlink(missing_ok=True)
        e.fsync_directory(root)
    (state/f"blocked-{slot}.sha256").unlink(missing_ok=True)
    for name in ("trial-a","trial-b","pending.json","rejected"):
        (state/name).unlink(missing_ok=True)
    e.atomic_json(e.LAST_RESULT,result)
    return True
