#!/bin/sh

OUTPUT_DEVICE="${OUTPUT_DEVICE:-default}"
MIXER_DEVICE="${MIXER_DEVICE:-$OUTPUT_DEVICE}"
MAC_ADDRESS="${MAC_ADDRESS:-02:00:00:00:00:00}"

ALSA_VOLUME_CONTROL=""
if [[ -n "$VOLUME_CONTROL" ]]; then
    ALSA_VOLUME_CONTROL=" -O ${MIXER_DEVICE} -V ${VOLUME_CONTROL}"
fi

POWER_SCRIPT=""
if [[ -n "$GPIO_PSU_RELAY" || -n "$GPIO_MUTE" || -n "$GPIO_SHUTDOWN" || -n "$GPIO_SPS" || -n "$HASS_SWITCH" ]]; then
    POWER_SCRIPT=" -S /usr/local/bin/power_mute.sh"
fi

LINE_IN_SCRIPT=""
if [[ -n "$INPUT_DEVICE" ]]; then
    LINE_IN_SCRIPT=" -T /usr/local/bin/line_in.sh"
fi

ADD_LOGGING=""
if [[ -n "$SQUEEZELITE_LOGGING" ]]; then
    ADD_LOGGING=" -d ${SQUEEZELITE_LOGGING}"
fi

# https://github.com/moby/moby/issues/31243#issuecomment-406879017
chmod o+w /dev/stdout

# run squeezelite with user squeezelite
# https://github.com/ralph-irving/squeezelite/issues/173#issuecomment-1944668435:
# will start with dac off if you use the name of the device with the -o option not the index number 
# and you specify the supported sample rates using -r 
exec su-exec squeezelite squeezelite -a 80:::0: -N /config/squeeze.name -o $OUTPUT_DEVICE -r 48000$ALSA_VOLUME_CONTROL -m $MAC_ADDRESS$POWER_SCRIPT$LINE_IN_SCRIPT$ADD_LOGGING