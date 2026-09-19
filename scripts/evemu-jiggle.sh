#!/bin/bash
# Default jiggle variant: emits tiny random relative mouse moves via evemu-event.
# Requires: evemu-tools, and sudo (NOPASSWD) rights for /usr/bin/evemu-event,
# since writing synthetic input events needs root.
set -u

_dev=$(ls -1 /dev/input/by-id/*event-mouse 2>/dev/null | tail -1)
if [ -z "${_dev}" ]; then
    echo "Cannot find mouse event device" >&2
    exit 1
fi
echo "Using ${_dev}"

_running=1
trap '_running=0' TERM INT

# Sleep in 1s slices so a stop/timeout signal is picked up within ~1s
# instead of waiting out a long sleep.
_sleep_interruptible() {
    local _secs=$1
    local _i=0
    while [ "${_i}" -lt "${_secs}" ] && [ "${_running}" -eq 1 ]; do
        sleep 1
        _i=$((_i + 1))
    done
}

while [ "${_running}" -eq 1 ]; do
    sudo /usr/bin/evemu-event "${_dev}" --type EV_REL --code REL_X --value $(( RANDOM % 8 + 1 - 4 )) --sync
    sudo /usr/bin/evemu-event "${_dev}" --type EV_REL --code REL_Y --value $(( RANDOM % 8 + 1 - 4 )) --sync
    _sleep_interruptible 10
done

echo "jiggle stopped"
