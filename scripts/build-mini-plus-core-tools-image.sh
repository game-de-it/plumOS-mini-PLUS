#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${PLUMOS_MINI_PLUS_DOCKER_IMAGE:-plumos-mini-plus-core-tools:dev}

exec docker build --platform linux/arm64 -t "$image" \
    -f "$repo_root/docker/plumos-mini-plus-core-tools/Dockerfile" "$repo_root"
