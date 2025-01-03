#!/bin/sh

# squeezelite power script
# squeezelite -S /path/to/power_mute.sh
# squeezelite sets $1 to
#   0: off
#   1: on
#   2: init

PSU_POWER_ON_DELAY="${PSU_POWER_ON_DELAY:-2}"
PSU_POWER_DOWN_DELAY="${PSU_POWER_DOWN_DELAY:-5}"

# disable script output by default
if [[ on != "$DEBUG_POWER_MUTE_SCRIPT" ]]; then
    ECHO_OUT=/dev/null
else
    ECHO_OUT=/dev/stdout
fi

# physical pin to BCM mapping
i=3 ; eval board_map$i="GPIO2" 
i=5 ; eval board_map$i="GPIO3" 
i=7 ; eval board_map$i="GPIO4" 
i=8 ; eval board_map$i="GPIO14" 
i=10 ; eval board_map$i="GPIO15" 
i=11 ; eval board_map$i="GPIO17" 
i=12 ; eval board_map$i="GPIO18" 
i=13 ; eval board_map$i="GPIO27" 
i=15 ; eval board_map$i="GPIO22" 
i=16 ; eval board_map$i="GPIO23"
i=18 ; eval board_map$i="GPIO24" 
i=19 ; eval board_map$i="GPIO10" 
i=21 ; eval board_map$i="GPIO9" 
i=22 ; eval board_map$i="GPIO25" 
i=23 ; eval board_map$i="GPIO11" 
i=24 ; eval board_map$i="GPIO8" 
i=26 ; eval board_map$i="GPIO7" 
i=29 ; eval board_map$i="GPIO5" 
i=31 ; eval board_map$i="GPIO6" 
i=32 ; eval board_map$i="GPIO12"
i=33 ; eval board_map$i="GPIO13" 
i=35 ; eval board_map$i="GPIO19" 
i=36 ; eval board_map$i="GPIO16" 
i=37 ; eval board_map$i="GPIO26" 
i=38 ; eval board_map$i="GPIO20" 
i=40 ; eval board_map$i="GPIO21"

# $1: GPIO board number
# $2: Set "--active-low" (e.g. for the muting ones)
gpio_init()
{
    eval BCM=\$board_map$1
    
    ADD_ACTIVE_LOW=""
    if [ -n "$2" ] && [ "$2" == "1" ]; then
        ADD_ACTIVE_LOW=" --active-low"
    fi
    
    gpiocli request --output$ADD_ACTIVE_LOW $BCM 1> /dev/null 2> /dev/null
}

# $1: GPIO board number
# $2: Value 0|1
gpio_set()
{
    eval BCM=\$board_map$1   
    
    if [ -n "$2" ]; then
        gpiocli set $BCM=$2 1> /dev/null 2> /dev/null
    fi
}

# $1: GPIO board number
gpio_get()
{
    eval BCM=\$board_map$1   
    
    GPIO_STATE=$(gpiocli get --numeric --unquoted $BCM 2> /dev/null)
    
    echo ${GPIO_STATE:0-1}
}

case $1 in
    # init
    2)
        # create lock in order to make sure we have exclusive access to GPIO
        exec 200>/var/lock/gpio || exit 1
        flock 200 || exit 1
        # move on with lock ...
        echo -n "init $OUTPUT_DEVICE: " > $ECHO_OUT
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            if [ "${GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN#*"$GPIO_MUTE"}" != "$GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN" ]; then
                echo -n "PSU relay: $GPIO_PSU_RELAY ..." > $ECHO_OUT
                gpio_init $GPIO_PSU_RELAY 0
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            echo -n "SPS: $GPIO_SPS ..." > $ECHO_OUT
            gpio_init $GPIO_SPS 0
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            echo -n "Mute: $GPIO_MUTE ..."  > $ECHO_OUT
            gpio_init $GPIO_MUTE 1
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            echo -n "Shutdown: $GPIO_SHUTDOWN ..." > $ECHO_OUT
            gpio_init $GPIO_SHUTDOWN 1
        fi
        echo "" > $ECHO_OUT
        # release gpio lock
        flock -u 200
        ;;
    # on
    1)
        # create lock in order to make sure we have exclusive access to GPIO
        exec 200>/var/lock/gpio || exit 1
        flock 200 || exit 1
        # move on with lock ...
        echo -n "power on $OUTPUT_DEVICE: " > $ECHO_OUT
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            if [ "${GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN#*"$GPIO_MUTE"}" != "$GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN" ]; then
                RELAY_ON=$(gpio_get $GPIO_PSU_RELAY)
                if [[ $RELAY_ON == 0 ]]; then
                    gpio_set $GPIO_PSU_RELAY 1
                    echo -n "PSU relay: $GPIO_PSU_RELAY ..." > $ECHO_OUT
                    # release gpio lock
                    flock -u 200
                    # wait without lock ...
                    sleep $PSU_POWER_ON_DELAY
                    # create lock in order to make sure we have exclusive access to GPIO
                    exec 200>/var/lock/gpio || exit 1
                    flock 200 || exit 1
                    # move on with lock ...
                fi
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            gpio_set $GPIO_SPS 1
            echo -n "SPS: $GPIO_SPS ..." > $ECHO_OUT
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            gpio_set $GPIO_SHUTDOWN 1
            echo -n "Shutdown: $GPIO_SHUTDOWN ..." > $ECHO_OUT
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            gpio_set $GPIO_MUTE 1
            echo -n "Mute: $GPIO_MUTE ..." > $ECHO_OUT
        fi
        # release gpio lock
        flock -u 200
        # hass without lock ...
        if [[ -n "$HASS_SWITCH" ]]; then
            curl -s -X POST -H "Authorization: Bearer $HASS_BEARER" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "'"$HASS_SWITCH"'"}' \
                http://$HASS_HOST/api/services/switch/turn_on
            echo -n "HASS switch: $HASS_SWITCH ..." > $ECHO_OUT
        fi
        echo "" > $ECHO_OUT
        ;;
    # off
    0)
        echo -n "power off $OUTPUT_DEVICE: " > $ECHO_OUT
        if [[ -n "$HASS_SWITCH" ]]; then
            curl -s -X POST -H "Authorization: Bearer $HASS_BEARER" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "'"$HASS_SWITCH"'"}' \
                http://$HASS_HOST/api/services/switch/turn_off
            echo -n "HASS switch: $HASS_SWITCH ..." > $ECHO_OUT
        fi
        # create lock in order to make sure we have exclusive access to GPIO
        exec 200>/var/lock/gpio || exit 1
        flock 200 || exit 1
        # move on with lock ...
        if [[ -n "$GPIO_MUTE" ]]; then
            if [[ -n "$GPIO_AMP_MUTE_ON_PLAYERS" ]]; then
                echo -n "Mute on players ..." > $ECHO_OUT
                ALL_OFF=1
                IFS=\;
                for token in $GPIO_AMP_MUTE_ON_PLAYERS; do
                    if [[ -n "$token" ]]; then
                        # check power state via lms api
                        DATA='{"id": 1, "method": "slim.request", "params":["'"$token"'", ["power", "?"]]}'
                        POWER=$(curl -s -H 'Content-Type: application/json' -d "$DATA" http://$LMS_HOST/jsonrpc.js)
                        # empty result if player not registered
                        if [[ -n "$POWER" ]]; then
                            PLAYER_ON=$(echo -n $POWER | jq -r '.result._power' )
                            if [[ $PLAYER_ON == 1 ]]; then
                                ALL_OFF=0
                                break
                            fi
                        fi
                    fi
                done
                if [[ $ALL_OFF == 1 ]]; then
                    gpio_set $GPIO_MUTE 0
                    echo -n "Mute: $GPIO_MUTE ..." > $ECHO_OUT
                fi
            else
                echo -n "Mute on GPIO ..." > $ECHO_OUT
                gpio_set $GPIO_MUTE 0
                echo -n "Mute: $GPIO_MUTE ..." > $ECHO_OUT
            fi
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            if [[ -n "$GPIO_AMP_SHUTDOWN_ON_AMP_MUTE" ]]; then
                echo -n "Shutdown on mute ($GPIO_AMP_SHUTDOWN_ON_AMP_MUTE) ..." > $ECHO_OUT
                GPIO_ON=$(gpio_get $GPIO_AMP_SHUTDOWN_ON_AMP_MUTE)
                if [[ $GPIO_ON == 1 ]]; then
                    gpio_set $GPIO_SHUTDOWN 0
                    echo -n "Shutdown: $GPIO_SHUTDOWN ..." > $ECHO_OUT
                fi
            else
                echo -n "Shutdown on GPIO ..."  > $ECHO_OUT
                gpio_set $GPIO_SHUTDOWN 0
                echo -n "Shutdown: $GPIO_SHUTDOWN ..." > $ECHO_OUT
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            gpio_set $GPIO_SPS 0
            echo -n "SPS: $GPIO_SPS ..." > $ECHO_OUT
        fi
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            if [ "${GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN#*"$GPIO_MUTE"}" != "$GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN" ]; then
                # release gpio lock
                flock -u 200
                # wait without lock ...
                sleep $PSU_POWER_DOWN_DELAY
                # create lock in order to make sure we have exclusive access to GPIO
                exec 200>/var/lock/gpio || exit 1
                flock 200 || exit 1
                # move on with lock ...
                ALL_OFF=1
                IFS=\;
                for token in $GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN; do
                    if [[ -n "$token" ]]; then
                        GPIO_ON=$(gpio_get $token)
                        if [[ $GPIO_ON == 1 ]]; then
                            ALL_OFF=0
                            break
                        fi
                    fi
                done
                if [[ $ALL_OFF == 1 ]]; then
                    gpio_set $GPIO_PSU_RELAY 0
                    echo -n "PSU relay: $GPIO_PSU_RELAY ..." > $ECHO_OUT
                fi
            fi
        fi
        echo "" > $ECHO_OUT
        # release gpio lock
        flock -u 200
        ;;
esac
