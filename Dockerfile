FROM alpine:3.13 as builder

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache git build-base wiringpi wiringpi-dev flac-dev alsa-lib-dev faad2-dev mpg123-dev libvorbis-dev libmad-dev soxr-dev openssl-dev opusfile-dev opus-dev libalac-dev

RUN mkdir -p /usr/local/src \
	&& cd /usr/local/src \
    && git clone --branch master --depth 1 https://github.com/ralph-irving/squeezelite.git \
    && cd squeezelite \
    && make OPTS="-DRESAMPLE -DDSD -DGPIO -DVISEXPORT -DUSE_SSL -DNO_SSLSYM -DOPUS -DALAC -I/usr/include/opus -I/usr/include/alac" \
    && gcc -Os -fomit-frame-pointer -fcommon -s -o find_servers tools/find_servers.c \
    && gcc -Os -fomit-frame-pointer -fcommon -s -o alsacap tools/alsacap.c -lasound 

COPY gpio.c /usr/local/src/gpio.c

RUN cd /usr/local/src \
    && gcc -o gpio gpio.c -Wall -Wextra -I/usr/local/include -Winline -pipe -lwiringPi -lwiringPiDev

FROM alpine:3.13

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache su-exec flac alsa-lib faad2 mpg123 libvorbis libmad soxr openssl opusfile libalac

# add group piaudio and pigpio with gid of underlying raspberry os groups
RUN addgroup -g 29 -S piaudio \
    && addgroup -g 997 -S pigpio \
    && adduser -S squeezelite \
    && addgroup squeezelite piaudio \
	&& addgroup squeezelite pigpio

# create file to be able to map host asound.conf
RUN touch /etc/asound.conf
	
COPY --from=builder /usr/local/src/squeezelite/squeezelite /usr/local/bin/squeezelite
#COPY --from=builder /usr/local/src/squeezelite/alsacap /usr/local/bin/alsacap
#COPY --from=builder /usr/local/src/squeezelite/find_servers /usr/local/bin/find_servers
COPY --from=builder /usr/local/src/gpio /usr/local/bin/gpio

COPY power_mute.sh /usr/local/bin/power_mute.sh
RUN chmod +x /usr/local/bin/power_mute.sh
COPY squeezelite.sh /usr/local/bin/squeezelite.sh
RUN chmod +x /usr/local/bin/squeezelite.sh

CMD [ "squeezelite.sh" ]