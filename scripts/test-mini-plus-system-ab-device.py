#!/usr/bin/env python3
"""Destructive, explicitly enabled System trial/recovery test on a handheld."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import tarfile
import tempfile
import time
import uuid

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"artifacts/device-validation/2026-10-31-pre-release"

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host",default="192.168.10.141")
    parser.add_argument("--allow-reboot-and-slot-failure",action="store_true",required=True)
    args=parser.parse_args()
    ssh=["sshpass","-e","ssh","-o","StrictHostKeyChecking=no","-o","UserKnownHostsFile=/dev/null",
         "-o","ConnectTimeout=4","root@"+args.host]
    def remote(command,data=None,check=True):
        for attempt in range(3):
            r=subprocess.run(ssh+[command],input=data,capture_output=True)
            # Authentication rejection happens before command execution; retrying
            # it cannot repeat a slot write or reboot already performed.
            if r.returncode==255 and b"Permission denied" in r.stderr and attempt<2:
                time.sleep(2)
                continue
            break
        if check and r.returncode: raise RuntimeError((command,r.returncode,r.stdout.decode(errors="replace"),r.stderr.decode(errors="replace")))
        return r
    def text(command): return remote(command).stdout.decode().strip()
    def read(path): return text("cat "+shlex.quote(path))
    def ready_after(old_id,timeout=150):
        deadline=time.monotonic()+timeout
        while time.monotonic()<deadline:
            r=remote("cat /proc/sys/kernel/random/boot_id; cat /tmp/plumos-fe-ready",check=False)
            lines=r.stdout.decode().splitlines()
            if not r.returncode and lines and lines[0]!=old_id and any(s.startswith("pid=") for s in lines):
                return lines[0]
            time.sleep(2)
        raise RuntimeError("handheld did not return to frontend after reboot")
    def reboot():
        old=read("/proc/sys/kernel/random/boot_id")
        remote("mkdir -p /run/plumos/power-action; printf reboot >/run/plumos/power-action/in-progress; "
               "(/bin/sh /storage/plumos/bin/plumos-safe-shutdown --reboot --poweroff || "
               "rm -f /run/plumos/power-action/in-progress) >/tmp/system-ab-test-reboot.log 2>&1 </dev/null &")
        return ready_after(old)
    def wait_result(result,slot):
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            try:
                value=json.loads(read("/storage/plumos/update-state/last-result.json"))
                if value.get("result")==result and read("/flash/System/active-slot")==slot: return value
            except (RuntimeError,json.JSONDecodeError): pass
            time.sleep(1)
        raise RuntimeError("System health result missing: "+result)
    def snapshot(name):
        data=text("cat /proc/sys/kernel/random/boot_id; cat /storage/plumos/state/system-ab/booted; cat /flash/System/active-slot; cat /etc/plumos-system-version; dmesg | grep plumos-system-ab")
        (OUT/("system-device-"+name+".log")).write_text(data+"\n")
        print(name+": "+data.splitlines()[0],flush=True)
    assert read("/flash/System/slot-policy")=="trial-v1"
    assert "(deleted)" not in read("/sys/block/loop0/loop/backing_file")
    assert read("/flash/System/active-slot")=="a","start with the original A slot"
    assert text("test ! -f /flash/System/pending-slot && printf clean")=="clean"
    initial_id=read("/proc/sys/kernel/random/boot_id")
    initial_settings=text("sha256sum /storage/plumos/config/system/settings.json /storage/plumos/config/frontend/settings.json /storage/plumos/config/network/services.conf")
    base=text("mktemp -d /storage/plumos/state/system-ab-device.XXXXXX")
    assert re.fullmatch(r"/storage/plumos/state/system-ab-device\.[A-Za-z0-9]+",base)
    inbox="/storage/user/updates/.system-ab-probe-"+uuid.uuid4().hex
    remote("set -eu; mkdir -p "+inbox+"; for slot in a b; do for ext in squashfs sha256 version; do cp /flash/System/system-$slot.$ext "+base+"/system-$slot.$ext; done; done; cp /flash/System/active-slot "+base+"/active-slot")
    original_version=read("/flash/System/system-a.version")
    def restore_a():
        remote(f'''set -eu
mount -o remount,rw /flash
trap 'mount -o remount,ro /flash' EXIT HUP INT TERM
for ext in squashfs sha256 version; do
 cp {base}/system-a.$ext /flash/System/system-a.$ext.next
 mv /flash/System/system-a.$ext.next /flash/System/system-a.$ext
done
sync
mount -o remount,ro /flash
trap - EXIT HUP INT TERM''')
    def restore_all():
        result=remote(f'''set -eu
booted=$(awk '{{print $1}}' /storage/plumos/state/system-ab/booted)
deferred=0
mount -o remount,rw /flash
trap 'mount -o remount,ro /flash' EXIT HUP INT TERM
for slot in a b; do for ext in squashfs sha256 version; do
 if cmp -s {base}/system-$slot.$ext /flash/System/system-$slot.$ext; then continue; fi
 if [ "$slot" = "$booted" ] && [ "$ext" = squashfs ]; then deferred=1; continue; fi
 cp {base}/system-$slot.$ext /flash/System/system-$slot.$ext.next
 mv /flash/System/system-$slot.$ext.next /flash/System/system-$slot.$ext
done; done
cp {base}/active-slot /flash/System/active-slot.next
mv /flash/System/active-slot.next /flash/System/active-slot
rm -f /flash/System/pending-slot
sync
mount -o remount,ro /flash
trap - EXIT HUP INT TERM
printf '%s\n' "$deferred"''')
        if result.stdout.strip()==b"1":
            # Select the restored A image, reboot away from the mounted changed
            # image, then restore the now-inactive slot. Never unlink loop0's file.
            reboot()
            restore_all()
        elif read("/storage/plumos/state/system-ab/booted").split()[0] != read(base+"/active-slot"):
            reboot()
            restore_all()
    try:
        with tempfile.TemporaryDirectory(prefix="mini-plus-system-key-") as temp:
            temp=Path(temp); key=temp/"private.pem"; public=temp/"public.pem"
            subprocess.run(["openssl","genpkey","-algorithm","ED25519","-out",str(key)],check=True,capture_output=True)
            subprocess.run(["openssl","pkey","-in",str(key),"-pubout","-out",str(public)],check=True,capture_output=True)
            specs=[("0.1.1-dev-system-probe",original_version,ROOT/"output/system-rootfs/mini-plus-frontend/payload/SYSTEM"),
                   ("0.1.2-dev-system-probe","0.1.1-dev-system-probe",OUT/"failing-system.squashfs"),
                   ("0.1.0-dev-system-rejected","0.1.1-dev-system-probe",ROOT/"output/system-rootfs/mini-plus-frontend/payload/SYSTEM")]
            packages=[]
            for version,source,image in specs:
                subprocess.run(["python3",str(ROOT/"scripts/build-mini-plus-update-package.py"),"--type","system","--input",str(image),
                  "--version",version,"--base-version",source,"--signing-key",str(key),"--output-dir",str(temp)],check=True,capture_output=True)
                packages.append(temp/f"plumos-mini-plus-system-{version}.tar.gz")
            archive=io.BytesIO()
            with tarfile.open(fileobj=archive,mode="w") as tar:
                for path in packages: tar.add(path,arcname=path.name)
            remote("tar xf - -C "+inbox,archive.getvalue())
            remote("cat >"+base+"/public.pem",public.read_bytes())
            def request(index,expected_error=None):
                command="PLUMOS_UPDATE_PROGRESS=0 PLUMOS_UPDATE_PUBLIC_KEY="+base+"/public.pem /bin/sh /storage/plumos/bin/plumos-system-update request "+inbox+"/"+packages[index].name
                r=remote(command,check=not bool(expected_error))
                if expected_error: assert r.returncode and expected_error.encode() in r.stderr,r.stderr
                return r
            request(0)
            assert read("/flash/System/pending-slot")=="b" and read("/flash/System/active-slot")=="a"
            reboot(); healthy=wait_result("system_healthy","b"); snapshot("healthy-b")
            assert read("/etc/plumos-system-version")=="0.1.1-dev-system-probe"
            request(2,"system downgrade is forbidden")
            request(1)
            reboot() # The failing trial init reboots itself; wait for the subsequent healthy FE.
            rollback=wait_result("system_rolled_back","b"); snapshot("failed-trial-rollback-b")
            failed_id=read("/storage/plumos/state/system-ab/probe-failed-boot")
            assert failed_id not in {initial_id,read("/proc/sys/kernel/random/boot_id")}
            remote("set -eu; mount -o remount,rw /flash; printf BROKEN >/flash/System/system-a.squashfs; sync; mount -o remount,ro /flash")
            reboot(); assert read("/flash/System/active-slot")=="b"; snapshot("corrupt-inactive-tolerated")
            restore_a()
            remote("set -eu; mount -o remount,rw /flash; printf 'invalid-checksum\\n' >/flash/System/system-b.sha256; sync; mount -o remount,ro /flash")
            reboot(); recovered=wait_result("system_recovered","a"); snapshot("invalid-active-recovered-a")
            restore_all()
            assert read("/flash/System/active-slot")=="a"
            assert read("/flash/System/system-a.version")==original_version
            after=text("sha256sum /storage/plumos/config/system/settings.json /storage/plumos/config/frontend/settings.json /storage/plumos/config/network/services.conf")
            assert initial_settings==after,"user settings changed"
            # Source images were restored with atomic rename, never truncated while mounted.
            expected=text("sha256sum "+base+"/system-a.squashfs "+base+"/system-b.squashfs").splitlines()
            actual=text("sha256sum /flash/System/system-a.squashfs /flash/System/system-b.squashfs").splitlines()
            assert [s.split()[0] for s in expected]==[s.split()[0] for s in actual]
            assert text("test ! -f /flash/System/pending-slot && printf clean")=="clean"
            assert "(deleted)" not in read("/sys/block/loop0/loop/backing_file")
            assert "ro" in text("awk '$2==\"/flash\" {print $4}' /proc/mounts").split(",")
            boot_patch=next(line.split("=",1)[1] for line in read("/flash/plumos-image.manifest").splitlines() if line.startswith("boot_patch_source_ref="))
            summary={"healthy_update":healthy,"failed_boot_rollback":rollback,"bad_active_recovery":recovered,
                     "inactive_corruption_tolerated":True,"system_downgrade_rejected":True,
                     "original_system_images_restored":True,"user_settings_preserved":True,"device_backup":base,
                     "boot_patch_retained":boot_patch,"application_patch_retained":json.loads(read("/storage/plumos/manifest.json"))["source_ref"],
                     "mounted_system_backing_file_intact":True,"boot_fat_read_only":True}
            (OUT/"system-device-summary.json").write_text(json.dumps(summary,indent=2)+"\n")
            print("device_system_ab=result-ok",flush=True)
    except BaseException:
        try:
            restore_all()
            print("original System files restored after test failure; reboot may still be needed",flush=True)
        except Exception as recovery:
            print("restore requires device access; host backup: "+str(OUT/"original-device"),recovery,flush=True)
        raise
    finally:
        remote("rm -f "+inbox+"/*; rmdir "+inbox,check=False)

if __name__=="__main__": main()
