#!/bin/sh

OUTPUT_DEVICE="${OUTPUT_DEVICE:-default}"
MAC_ADDRESS="${MAC_ADDRESS:-02:00:00:00:00:00}"

POWER_SCRIPT=""
if [[ -n "$GPIO_PSU_RELAY" || -n "$GPIO_MUTE" || -n "$GPIO_SHUTDOWN" || -n "$GPIO_SPS" || -n "$HASS_SWITCH" ]]; then
    POWER_SCRIPT=" -S /usr/local/bin/power_mute.sh"
fi

# run squeezelite with user squeezelite
exec su-exec squeezelite squeezelite -a 80:::0: -N /config/squeeze.name -o $OUTPUT_DEVICE -m $MAC_ADDRESS$POWER_SCRIPT