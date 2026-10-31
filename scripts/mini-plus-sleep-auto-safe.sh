#!/bin/sh
exec /bin/busybox sh /storage/plumos/bin/plumos-safe-shutdown \
    "$@" --wakeup-sec 7
