#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
echo 'note: the legacy seed verifier is superseded by verify-mini-plus-image.sh' >&2
exec "$repo_root/scripts/verify-mini-plus-image.sh" "$@"
