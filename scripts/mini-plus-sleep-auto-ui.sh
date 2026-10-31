#!/bin/sh
exec /bin/busybox sh /storage/plumos/bin/plumos-controller-ui-mini-plus \
    "$@" --script up,up,up,a
