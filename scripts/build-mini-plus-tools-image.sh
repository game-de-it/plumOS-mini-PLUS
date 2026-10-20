#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}
docker build --platform linux/arm64 -t "$image" \
    -f "$repo_root/docker/mini-plus-tools/Dockerfile" "$repo_root"
