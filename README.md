# Squeezelite Docker

[Squeezelite](https://github.com/ralph-irving/squeezelite) docker to run on Raspberry Pi. 

Features:
* squeezelite player
* un-/mute amp and power supply
* based on Alpine Linux
* Container init via [Tini](https://github.com/krallin/tini)
* rootless via [su-exec](https://github.com/ncopa/su-exec)
* supports [alsaequal](https://github.com/raedwulf/alsaequal)

## Docker build

```
sudo docker build -t squeezelite .
```

## Docker run

With defaults and without GPIO script:
```
sudo docker run -d --network host --device /dev/gpiomem --device /dev/snd --ipc="host" --mount type=bind,source=/etc/asound.conf,target=/etc/asound.conf,readonly --mount type=bind,source=/home/pi/squeezenames/squeeze1.name,target=/config/squeeze.name squeezelite 
```

Custom config via env:
```
sudo docker run -d --network host --device /dev/gpiomem --device /dev/snd --ipc="host" --mount type=bind,source=/etc/asound.conf,target=/etc/asound.conf,readonly --mount type=bind,source=/home/pi/squeezenames/squeeze1.name,target=/config/squeeze.name --env OUTPUT_DEVICE=default --env MAC_ADDRESS=02:00:00:00:00:00 --env GPIO="15;7;15:18:22:31:32:36:35:40" squeezelite
```

Env variables:
* OUTPUT_DEVICE: ALSA output device
* MAC_ADDRESS: mac for LMS player instance
* HASS_HOST: home assistant IP or hostname
* HASS_BEARER: home assistant bearer token
* LMS_HOST: Logitect Media Server IP or hostname
* GPIO_PSU_RELAY: GPIO number for relay shutting down power supply
* GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN: GPIO numbers to check for amp shutdown (';' separated)
* GPIO_AMP_SHUTDOWN_ON_AMP_MUTE: GPIO to check if amp should be shut down
* GPIO_AMP_MUTE_ON_PLAYERS: mute amp when players muted (list of ';' separated mac addresses)
* GPIO_MUTE: GPIO to mute amp
* GPIO_SHUTDOWN: GPIO to shutdown amp
* GPIO_SPS: speaker switch GPIO
* HASS_SWITCH: switch that should be controlled via home assistant

Player Name via config file:
* The best way to define the player name for squeezelite is the -N command line option. 
* With -N you can set/change the name from LMS and squeezelite updates the file with the new name.

Requires access to /dev/gpiomem and /dev/snd devices. The IPC setting is for ALSA dmix to work across containers. The hosts asound.conf is mounted into the container.

## Power mute script / GPIO config:

A power mute script can mute/power down the connected amp via a GPIO. It also allows to power down the power supply if all connected amps are off. 
The speaker switcher GPIO is used to trigger an external 5V relais changing speakers between sqeezeMultiAmp and another amp in the room.
Additionally an external switch can be controlled via home assistant.

The [power_mute.sh](power_mute.sh) script is automatically configured via the `-S` squeezelite parameter when one of the relevant ENV vars is present in the docker run command. 
It uses a custom [gpio control binary](gpio.c) based on [lgpio](https://github.com/joan2937/lg).

[flock](https://linux.die.net/man/1/flock) is used to prevent race conditions of parallel running scripts for different player instances.

## Docker dev

Run and login to shell:
```
sudo docker run -it --network host --device /dev/gpiomem --device /dev/snd --ipc="host" squeezelite /bin/sh
```
Login to running container:
```
sudo docker exec -it <name> /bin/sh
```

Notes:
* [Squeezelite command line options](https://ralph-irving.github.io/squeezelite.html)
* [Power script example](https://github.com/ralph-irving/squeezelite/blob/master/tools/gpiopower.sh)
* [flock example](https://www.kiloroot.com/bash-two-methods-for-job-control-simple-lock-files-and-flock/)
* https://stackoverflow.com/questions/2829613/how-do-you-tell-if-a-string-contains-another-string-in-posix-sh

## Ideas

* build alpine packages for squeezelite and libs: https://wiki.alpinelinux.org/wiki/Abuild_and_Helpers#Setting_up_the_build_environment