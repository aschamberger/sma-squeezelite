#!/bin/sh

# squeezelite power script
# squeezelite -S /path/to/power_mute.sh
# squeezelite sets $1 to
#   0: off
#   1: on
#   2: init

#echo "power/mute ..."

# create lock in order to make sure we have exclusive access to GPIO
exec 200>/var/lock/gpio || exit 1
flock 200 || exit 1

case $1 in
    # init
    2)
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            # set output mode if not initialized yet
            RELAY_MODE=$(gpio get_mode $GPIO_PSU_RELAY)
            if [[ $RELAY_MODE == 0 ]]; then
                gpio set_mode $GPIO_PSU_RELAY 1
                gpio write $GPIO_PSU_RELAY 0
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            # set output mode if not initialized yet
            SPEAKER_SWITCHER_MODE=$(gpio get_mode $GPIO_SPS)
            if [[ $SPEAKER_SWITCHER_MODE == 0 ]]; then
                gpio set_mode $GPIO_SPS 1
                gpio write $GPIO_SPS 0
            fi
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            # set output mode if not initialized yet
            MUTE_MODE=$(gpio get_mode $GPIO_MUTE)
            if [[ $MUTE_MODE == 0 ]]; then
                gpio set_mode $GPIO_MUTE 1
                gpio write $GPIO_MUTE 1
            fi
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            # set output mode if not initialized yet
            SHUTDOWN_MODE=$(gpio get_mode $GPIO_SHUTDOWN)
            if [[ $SHUTDOWN_MODE == 0 ]]; then
                gpio set_mode $GPIO_SHUTDOWN 1
                gpio write $GPIO_SHUTDOWN 1
            fi
        fi
        #echo "init\n"
        ;;
    # on
    1)
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            RELAY_ON=$(gpio read $GPIO_PSU_RELAY)
            if [[ $RELAY_ON == 0 ]]; then
                gpio write $GPIO_PSU_RELAY 1
                sleep 2
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            gpio write $GPIO_SPS 1
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            gpio write $GPIO_SHUTDOWN 0
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            gpio write $GPIO_MUTE 0
        fi
        if [[ -n "$HASS_SWITCH" ]]; then
            curl -X POST -H "Authorization: Bearer $HASS_BEARER" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "'"$HASS_SWITCH"'"}' \
                http://$HASS_HOST/api/services/switch/turn_on
        fi
        #echo "on\n"
        ;;
    # off
    0)
        if [[ -n "$HASS_SWITCH" ]]; then
            curl -X POST -H "Authorization: Bearer $HASS_BEARER" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "'"$HASS_SWITCH"'"}' \
                http://$HASS_HOST/api/services/switch/turn_off
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            if [[ -n "$GPIO_AMP_MUTE_ON_PLAYERS" ]]; then
                ALL_OFF=1
                IFS=\;
                for token in $GPIO_AMP_MUTE_ON_PLAYERS; do
                    if [[ -n "$token" ]]; then
                        # check power state via lms api
                        DATA='{"id": 1, "method": "slim.request", "params":["'"$token"'", ["power", "?"]]}'
                        POWER=$(curl -H 'Content-Type: application/json' -d "$DATA" http://$LMS_HOST/jsonrpc.js)
                        # empty result if player not registered
                        if [[ -n $POWER ]]
                            PLAYER_ON=$(echo $POWER | jq -r '.result._power' )
                            if [[ $PLAYER_ON == 0 ]]; then
                                ALL_OFF=0
                                break
                            fi
                        fi
                    fi
                done
                if [[ $ALL_OFF == 1 ]]; then
                    gpio write $GPIO_MUTE 1
                fi
            else
                gpio write $GPIO_MUTE 1
            fi
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            if [[ -n "$GPIO_AMP_SHUTDOWN_ON_AMP_MUTE" ]]; then
                GPIO_ON=$(gpio read $GPIO_AMP_SHUTDOWN_ON_AMP_MUTE)
                if [[ $GPIO_ON == 0 ]]; then
                    gpio write $GPIO_SHUTDOWN 1
                fi
            else
                gpio write $GPIO_SHUTDOWN 1
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            gpio write $GPIO_SPS 0
        fi
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            sleep 5
            ALL_OFF=1
            IFS=\;
            for token in $GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN; do
                if [[ -n "$token" ]]; then
                    GPIO_ON=$(gpio read $token)
                    if [[ $GPIO_ON == 0 ]]; then
                        ALL_OFF=0
                        break
                    fi
                fi
            done
            if [[ $ALL_OFF == 1 ]]; then
                gpio write $GPIO_PSU_RELAY 0
            fi
        fi
        #echo "off\n"
        ;;
esac

# release gpio lock
flock -u 200
