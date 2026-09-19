#!/bin/bash
# Alternative jiggle variant: uses ydotool, no per-call sudo needed.
# Requires: the `ydotool` package and a running `ydotoold` user/system service
# (check `ydotool mousemove --help` on your system - relative-move flags
# differ slightly between ydotool versions).
set -u

if ! command -v ydotool >/dev/null 2>&1; then
    echo "ydotool not found - install it and make sure ydotoold is running" >&2
    exit 1
fi

_running=1
trap '_running=0' TERM INT

_sleep_interruptible() {
    local _secs=$1
    local _i=0
    while [ "${_i}" -lt "${_secs}" ] && [ "${_running}" -eq 1 ]; do
        sleep 1
        _i=$((_i + 1))
    done
}

while [ "${_running}" -eq 1 ]; do
    ydotool mousemove --relative -- $(( RANDOM % 8 + 1 - 4 )) $(( RANDOM % 8 + 1 - 4 ))
    _sleep_interruptible 10
done

echo "jiggle stopped"
