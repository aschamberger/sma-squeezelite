#!/bin/sh

OUTPUT_DEVICE="${OUTPUT_DEVICE:-default}"
MIXER_DEVICE="${MIXER_DEVICE:-$OUTPUT_DEVICE}"
MAC_ADDRESS="${MAC_ADDRESS:-02:00:00:00:00:00}"

POWER_SCRIPT=""
if [[ -n "$GPIO_PSU_RELAY" || -n "$GPIO_MUTE" || -n "$GPIO_SHUTDOWN" || -n "$GPIO_SPS" || -n "$HASS_SWITCH" ]]; then
    POWER_SCRIPT=" -S /usr/local/bin/power_mute.sh"
fi

LINE_IN_SCRIPT=""
if [[ -n "$INPUT_DEVICE" ]]; then
    LINE_IN_SCRIPT=" -T /usr/local/bin/line_in.sh"
fi

ALSA_VOLUME_CONTROL=""
if [[ -n "$VOLUME_CONTROL" ]]; then
    ALSA_VOLUME_CONTROL=" -O ${MIXER_DEVICE} -V ${VOLUME_CONTROL}"
fi

# https://github.com/moby/moby/issues/31243#issuecomment-406879017
chmod o+w /dev/stdout

# run squeezelite with user squeezelite
exec su-exec squeezelite squeezelite -a 80:::0: -N /config/squeeze.name -o $OUTPUT_DEVICE$ALSA_VOLUME_CONTROL -m $MAC_ADDRESS$POWER_SCRIPT$LINE_IN_SCRIPT