#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
expected=$(openssl passwd -6 -salt plumos-mini-plus plumos)

for shadow in \
    "$repo_root/rootfs/mini-plus-minimal/etc/shadow" \
    "$repo_root/rootfs/mini-plus-frontend/etc/shadow"; do
    actual=$(cut -d: -f2 "$shadow")
    test "$actual" = "$expected"
done

grep -Fq '`root` / `plumos`' "$repo_root/README.md"
grep -Fq 'dropbear -E' "$repo_root/rootfs/mini-plus-frontend/init"
grep -Fq -- '-p 22' "$repo_root/rootfs/mini-plus-frontend/init"

echo 'miniplus_recovery_credentials=result-ok user=root password=plumos port=22'
