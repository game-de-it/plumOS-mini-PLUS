#!/bin/sh
set -eu

# The former implementation created a fixed 4 GiB p2 and mixed managed
# Runtime with mutable/user state. That artifact is retained only as historical
# bring-up evidence. The canonical full build is the measured three-partition
# seed with System A/B and first-boot p4 provisioning.
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUMOS_MINI_PLUS_VERSION=${PLUMOS_MINI_PLUS_VERSION:-$(cat "$repo_root/VERSION")}
export PLUMOS_MINI_PLUS_VERSION

case "${1:-}" in
    '') ;;
    --assemble-only)
        export PLUMOS_MINI_PLUS_APP_ASSEMBLE_ONLY=1
        ;;
    *)
        echo "usage: $0 [--assemble-only]" >&2
        exit 2
        ;;
esac

echo 'miniplus_full_image=delegating layout=system-ab,p2-matching,p3-measured,p4-first-boot' >&2
exec "$repo_root/scripts/build-mini-plus-frontend-probe-image.sh"
