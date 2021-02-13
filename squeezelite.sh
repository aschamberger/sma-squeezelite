#!/bin/sh

PLAYER_NAME=${PLAYER_NAME:-squeezelite-docker}
OUTPUT_DEVICE=${OUTPUT_DEVICE:-default}
MAC_ADDRESS=${MAC_ADDRESS:-02:00:00:00:00:00}

POWER_SCRIPT=""
if [ -n "$GPIO" ]; then
    POWER_SCRIPT=" -S /usr/local/bin/power_mute.sh"
fi

# run squeezelite with user squeezelite
exec su-exec squeezelite squeezelite -n "$PLAYER_NAME" -o "$OUTPUT_DEVICE" -a 80:::0 -m "$MAC_ADDRESS""$POWER_SCRIPT"