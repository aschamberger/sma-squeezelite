#!/bin/sh

# squeezelite gpio power script
# squeezelite -S /path/to/power_mute.sh
# squeezelite sets $1 to
#   0: off
#   1: on
#   2: init

GPIO=${GPIO:-;;}

#echo "power/mute ..."

IFS=\;
COUNTER=0
for token in $GPIO; do
    case $COUNTER in
        0)
            GPIO_MUTE=$token
            ;;
        1)
            GPIO_RELAY=$token
            ;;
        2)
            GPIO_ALL_MUTE=$token
            ;;
        3)
            GPIO_SPEAKER_SWITCHER=$token
            ;;
    esac
    COUNTER=$(($COUNTER+1))
done

case $1 in
    # init
    2)
        if [ -n "$GPIO_RELAY" ]; then
            # set output mode if not initialized yet
            RELAY_MODE=$(gpio get_mode $GPIO_RELAY)
            if [ $RELAY_MODE == 0 ]; then
                gpio set_mode $GPIO_RELAY 1
                gpio write $GPIO_RELAY 0
            fi
        fi
        gpio set_mode $GPIO_MUTE 1
        gpio write $GPIO_MUTE 1
        #echo "init\n"
        ;;
    # on
    1)
        if [ -n "$GPIO_RELAY" ]; then
            RELAY_ON=$(gpio read $GPIO_RELAY)
            if [ $RELAY_ON == 0 ]; then
                gpio write $GPIO_RELAY 1
            fi
        fi
        if [ -n "$GPIO_SPEAKER_SWITCHER" ]; then
            gpio write $GPIO_SPEAKER_SWITCHER 1
        fi
        gpio write $GPIO_MUTE 0
        #echo "on\n"
        ;;
    # off
    0)
        gpio write $GPIO_MUTE 1
        if [ -n "$GPIO_SPEAKER_SWITCHER" ]; then
            gpio write $GPIO_SPEAKER_SWITCHER 0
        fi
        if [ -n "$GPIO_RELAY" ]; then
            ALL_MUTE=1
            IFS=\:
            for token in $GPIO_ALL_MUTE; do
                if [ -n "$token" ]; then
                    GPIO_ON=$(gpio read $token)
                    if [ GPIO_ON == 1 ]; then
                        ALL_MUTE=0
                        break
                    fi
                fi
            done
            if [ $ALL_MUTE == 1 ]; then
                gpio write $GPIO_RELAY 0
            fi
        fi
        #echo "off\n"
        ;;
esac
