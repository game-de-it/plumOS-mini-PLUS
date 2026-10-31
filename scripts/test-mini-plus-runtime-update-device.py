#!/usr/bin/env python3
"""Run the installed updater in a disposable device-side state directory."""
import argparse
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

REPO = Path(__file__).resolve().parents[1]
HARNESS = r'''
import json, os, subprocess, sys
from pathlib import Path
root = Path(sys.argv[1])
installed = root / "installed"
env = os.environ.copy()
env.update(PLUMOS_ROOT=str(installed), PLUMOS_USERDATA_ROOT=str(root/"user"),
 PLUMOS_UPDATE_PUBLIC_KEY=str(root/"public.pem"), PLUMOS_UPDATE_OPENSSL=str(root/"openssl"),
 PLUMOS_SYSTEM_ABI_FILE=str(root/"system-abi"), PLUMOS_UPDATE_LOCK_FILE=str(root/"update.lock"),
 PLUMOS_UPDATE_TMP=str(root), PLUMOS_UPDATE_PROGRESS="0",
 PLUMOS_MINI_PLUS_PYTHON_ROOT="/storage/plumos/apps/python",
 PLUMOS_MINI_PLUS_PYXEL_ROOT="/storage/plumos/apps/pyxel")
cmd = ["/bin/sh", "/storage/plumos/bin/plumos-python-mini-plus",
       "/storage/plumos/share/update/plumos-system-update.py"]
def run(*args, rejected=None):
 r = subprocess.run(cmd+list(args), env=env, text=True, capture_output=True)
 if rejected:
  assert r.returncode != 0 and rejected in r.stderr, (args,r.stdout,r.stderr)
 else:
  assert r.returncode == 0, (args,r.stdout,r.stderr)
 return r.stdout
inbox=root/"user/updates"
p11=inbox/"plumos-mini-plus-runtime-1.1.0.tar.gz"
p12=inbox/"plumos-mini-plus-runtime-1.2.0.tar.gz"
bad=inbox/"invalid-signature.tar.gz"
run("request",str(bad),rejected="signature verification failed")
assert not (installed/"update-state/request.json").exists()
run("request",str(p11)); run("apply-pending")
assert (installed/"VERSION").read_text().strip()=="1.1.0"
assert not (installed/"bin/remove-on-update").exists()
run("apply-pending")
assert (installed/"VERSION").read_text().strip()=="1.0.0"
assert (installed/"bin/remove-on-update").read_text().strip()=="old"
run("request",str(p11)); run("apply-pending"); run("mark-healthy")
assert json.loads((installed/"update-state/last-result.json").read_text())["result"]=="runtime_healthy"
run("request",str(inbox/"plumos-mini-plus-runtime-1.0.0.tar.gz"),rejected="runtime downgrade is forbidden")
assert not (installed/"update-state/request.json").exists()
run("request",str(p12)); run("apply-pending"); run("apply-pending")
assert (installed/"VERSION").read_text().strip()=="1.1.0"
assert (installed/"bin/runtime-probe").read_text().strip()=="runtime-two"
assert json.loads((installed/"config/system/settings.json").read_text())=={"preserve":"user-setting"}
assert not (installed/"update-state/runtime-pending.json").exists()
print("device_runtime_update=result-ok signature_rejection=yes healthy_commit=yes rollback=2 downgrade_rejected=yes user_setting_preserved=yes")
'''

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="192.168.10.141")
    args = parser.parse_args()
    # Authentication uses the caller's SSHPASS, never a generated shell command.
    ssh = ["sshpass", "-e", "ssh", "-o", "StrictHostKeyChecking=no",
           "-o", "UserKnownHostsFile=/dev/null", "-o", "ConnectTimeout=6", "root@"+args.host]
    def remote(command, data=None):
        return subprocess.run(ssh+[command],input=data,capture_output=True,check=True).stdout
    spec = importlib.util.spec_from_file_location("fixture", REPO/"tests/test-mini-plus-runtime-update.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    with tempfile.TemporaryDirectory(prefix="mini-plus-update-fixture-") as temp:
        base=Path(temp); payload=base/"payload"; payload.mkdir()
        installed=payload/"installed"
        fixture.write_runtime(installed,"1.0.0","runtime-one",deleted_file=True)
        versions=[]
        for version,content in [("1.1.0","runtime-two"),("1.2.0","runtime-three"),("1.0.0","runtime-downgrade")]:
            path=base/version
            fixture.write_runtime(path,version,content,deleted_file=False)
            versions.append(path)
        key=base/"private.pem"
        fixture.run(["openssl","genpkey","-algorithm","ED25519","-out",str(key)])
        fixture.run(["openssl","pkey","-in",str(key),"-pubout","-out",str(payload/"public.pem")])
        inbox=payload/"user/updates"; inbox.mkdir(parents=True)
        p11=fixture.build_package(versions[0],inbox,key,"1.1.0","1.0.0",installed)
        fixture.build_package(versions[1],inbox,key,"1.2.0","1.1.0",versions[0])
        fixture.build_package(versions[2],inbox,key,"1.0.0","1.1.0",versions[0])
        with tarfile.open(p11,"r:gz") as source, tarfile.open(inbox/"invalid-signature.tar.gz","w:gz") as dest:
            for member in source:
                content=source.extractfile(member).read() if member.isfile() else None
                if member.name=="META/manifest.sig": content=bytes([content[0]^1])+content[1:]
                dest.addfile(member,io.BytesIO(content) if content is not None else None)
        (payload/"system-abi").write_text("1\n")
        (payload/"openssl").write_text('#!/bin/sh\nPLUMOS_ROOT=/storage/plumos exec /bin/sh /storage/plumos/bin/plumos-openssl "$@"\n')
        (payload/"openssl").chmod(0o755)
        (payload/"check.py").write_text(HARNESS)
        archive=io.BytesIO()
        with tarfile.open(fileobj=archive,mode="w") as tar: tar.add(payload,arcname=".")
        sandbox=remote("mktemp -d /storage/plumos/state/prerelease-update.XXXXXX").decode().strip()
        assert re.fullmatch(r"/storage/plumos/state/prerelease-update\.[A-Za-z0-9]+",sandbox)
        before=remote("sha256sum /storage/plumos/checksums.sha256 /storage/plumos/manifest.json /storage/plumos/config/system/settings.json /storage/plumos/config/network/services.conf")
        try:
            remote("tar xf - -C "+sandbox,archive.getvalue())
            result=remote("/bin/sh /storage/plumos/bin/plumos-python-mini-plus "+sandbox+"/check.py "+sandbox)
            print(result.decode(),end="")
            after=remote("sha256sum /storage/plumos/checksums.sha256 /storage/plumos/manifest.json /storage/plumos/config/system/settings.json /storage/plumos/config/network/services.conf")
            assert before==after,"live metadata/user settings changed during isolated test"
            print("live_state_preserved=yes fixture_archive_sha256="+hashlib.sha256(archive.getvalue()).hexdigest())
        finally:
            remote("rm -rf "+sandbox)

if __name__=="__main__": main()
