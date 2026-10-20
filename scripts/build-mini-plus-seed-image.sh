#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
echo 'note: the legacy Bubble-derived seed builder is superseded by build-mini-plus-image.sh' >&2
exec "$repo_root/scripts/build-mini-plus-image.sh" "$@"
