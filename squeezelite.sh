#!/bin/sh

OUTPUT_DEVICE=${OUTPUT_DEVICE:-default}
MAC_ADDRESS=${MAC_ADDRESS:-02:00:00:00:00:00}

POWER_SCRIPT=""
if [ -n "$GPIO" ]; then
    POWER_SCRIPT=" -S /usr/local/bin/power_mute.sh"
fi

# run squeezelite with user squeezelite
exec su-exec squeezelite squeezelite -N /config/squeeze.name -o $OUTPUT_DEVICE -m $MAC_ADDRESS$POWER_SCRIPT