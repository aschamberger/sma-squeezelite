# Squeezelite Docker

[Squeezelite](https://github.com/ralph-irving/squeezelite) docker to run on Raspberry Pi. 

Features:
* squeezelite player
* un-/mute amp and power supply
* based on Alpine Linux
* rootless via [su-exec](https://github.com/ncopa/su-exec)

## Docker build

```
sudo docker build -t squeezelite .
```

## Docker run

With defaults and without GPIO script:
```
sudo docker run -d --network host --device /dev/gpiomem --device /dev/snd --ipc="host" --mount type=bind,source=/etc/asound.conf,target=/etc/asound.conf,readonly squeezelite 
```

Custom config via env:
```
sudo docker run -d --network host --device /dev/gpiomem --device /dev/snd --ipc="host" --mount type=bind,source=/etc/asound.conf,target=/etc/asound.conf,readonly --env PLAYER_NAME=test123 --env OUTPUT_DEVICE=default --env MAC_ADDRESS=02:00:00:00:00:00 --env GPIO="8;4;8:12:26:20:21::" squeezelite
```
Env variables:
* PLAYER_NAME: Player name to display in Logitech Media Server
* OUTPUT_DEVICE: ALSA output device
* MAC_ADDRESS: mac for LMS player instance
* GPIO: config for muting amp and power supply (see next section)

Requires access to /dev/gpiomem and /dev/snd devices. The IPC setting is for ALSA dmix to work across containers. The hosts asound.conf is mounted into the container.

## Power mute script / GPIO config:

A power mute script can mute/power down the connected amp via a GPIO (first parameter). The second parameter allows to power down the power supply if all connected amps (listed in third parameter) are off.

Pi GPIO config is done using board GPIO numbers (not BCM oder WiringPi numbering scheme) - `<current amp GPIO>;<power relay GPIO>;<all up to 8 amp GPIOs>`:
```
8;4;8:12:26:20:21::
```

The [power_mute.sh](power_mute.sh) script is automatically configured via the `-S` squeezelite parameter when the GPIO config is present in the docker run command. 
It uses a custom [gpio control binary](gpio.c) based on [WiringPi](https://github.com/WiringPi/WiringPi).

## Docker dev

Run and login to shell:
```
sudo docker run -it --network host --device /dev/gpiomem --device /dev/snd squeezelite /bin/sh
```
Login to running container:
```
sudo docker exec -it <name> /bin/sh
```

Notes:
* [Squeezelite command line options](https://ralph-irving.github.io/squeezelite.html)
* [Power script example](https://github.com/ralph-irving/squeezelite/blob/master/tools/gpiopower.sh)
