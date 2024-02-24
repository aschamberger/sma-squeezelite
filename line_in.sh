#!/bin/sh

# squeezelite line-in script
# squeezelite -T /path/to/line_in.sh
# squeezelite sets $1 to
#   0: off
#   1: on
#   2: level

DEBUG_LINE_IN_SCRIPT="on"
MIXER_DEVICE_LINE="snda"
SOFTVOL_CONTROL_LINE="SoftVolLi1"
INPUT_DEVICE="li1_sv"

CHANNEL=$((10#${MAC_ADDRESS:(-2)}))
PID_FILE="/run/ch${CHANNEL}_line_in.pid"

# disable script output by default
if [[ on != "$DEBUG_LINE_IN_SCRIPT" ]]; then
    echo () { :; }
    OUT=/dev/null
else
    OUT=/dev/stdout
fi

case $1 in
    # level
    2)
        echo "Set volume of $SOFTVOL_CONTROL_LINE to: $2%."
        if [[ ! -z "$2" && $((10#$2)) -ge 0 && $((10#$2)) -le 100 ]]; then
            amixer -D $MIXER_DEVICE_LINE sset $SOFTVOL_CONTROL_LINE $2% > $OUT
        else
            echo "Volume must be given betwenn 0 and 100%."
            exit
        fi
        echo ""
        ;;
    # on
    1)
        if [ ! -f $PID_FILE ]; then
            echo "Start looping from $INPUT_DEVICE to $OUTPUT_DEVICE."
            nohup arecord -d0 -c2 -f S16_LE -r 44100 -traw -D $INPUT_DEVICE | aplay -c2 -f S16_LE -r 44100 -traw -D $OUTPUT_DEVICE - 1>/dev/null 2>/dev/null &
            echo $! > $PID_FILE
            cat $PID_FILE
        else
            echo "Found .pid file named $PID_FILE. Instance of application already exists. Exiting."
            exit
        fi
        echo ""
        ;;
    # off
    0)
        echo "Stop looping from $INPUT_DEVICE to $OUTPUT_DEVICE."
        if [ -f $PID_FILE ]; then
            cat $PID_FILE > $OUT
            cat $PID_FILE | xargs kill > $OUT
            rm $PID_FILE
        else
            echo "No .pid file named $PID_FILE. Exiting."
            exit
        fi
        echo ""
        ;;
esac