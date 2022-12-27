FROM alpine:3.17 as builder

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache wget unzip build-base autoconf automake wiringpi wiringpi-dev flac-dev alsa-lib-dev faad2-dev mpg123-dev libvorbis-dev libmad-dev soxr-dev openssl-dev opusfile-dev opus-dev libogg-dev libtool linux-headers

RUN mkdir -p /usr/local/src \
    && cd /usr/local/src \
    && mkdir dest \
    && wget https://github.com/ralph-irving/squeezelite/archive/master.zip -O squeezelite.zip \
    && unzip squeezelite.zip \
    && wget https://github.com/TimothyGu/alac/archive/master.zip -O libalac.zip \
    && unzip libalac.zip \
    && wget https://gitlab.xiph.org/xiph/tremor/-/archive/master/tremor-master.zip -O libtremor.zip \
    && unzip libtremor.zip \
    && cd alac-master \
    && patch -p1 -i ../squeezelite-master/alpine/libalac/fix-arm-segfault.patch \
    && patch -p1 -i ../squeezelite-master/alpine/libalac/alac-version.patch \
    && autoreconf -if \
    && ./configure --prefix=/usr \
    && make -j1 \
    && make install \
    && make DESTDIR="/usr/local/src/dest" install \
    && cd .. \
    && cd tremor-master \
    && sed -i "s/\(XIPH_PATH_OGG(, AC_MSG_ERROR(must have Ogg installed!))\)/#\1/" configure.in \
    && ./autogen.sh --prefix=/usr --enable-static=no \
    && make \
    && make install \
    && make DESTDIR="/usr/local/src/dest" install \
    && cd .. \
    && cd squeezelite-master \
    && patch -p1 -i alpine/load-libtremor-first.patch \
    && make OPTS="-DRESAMPLE -DDSD -DGPIO -DVISEXPORT -DUSE_SSL -DNO_SSLSYM -DOPUS -DALAC -I/usr/include/opus -I/usr/include/alac" \
    && gcc -Os -fomit-frame-pointer -fcommon -s -o find_servers tools/find_servers.c \
    && gcc -Os -fomit-frame-pointer -fcommon -s -o alsacap tools/alsacap.c -lasound 

COPY gpio.c /usr/local/src/gpio.c

RUN cd /usr/local/src \
    && gcc -o gpio gpio.c -Wall -Wextra -Winline -I/usr/include -L/usr/lib -pipe -lwiringPi
    
RUN cd /usr/local/src \
    && wget https://github.com/raedwulf/alsaequal/archive/refs/heads/master.zip -O alsaequal.zip \
    && unzip alsaequal.zip \
    && cd alsaequal-master \
    && make \
    && mkdir -p /usr/lib/alsa-lib \
    && make install

FROM alpine:3.17

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache tini su-exec flac alsa-lib faad2-libs mpg123-libs libvorbis libmad soxr openssl opusfile libogg curl jq flock

RUN apk add caps --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

# add group piaudio and pigpio with gid of underlying raspberry os groups
RUN addgroup -g 29 -S piaudio \
    && addgroup -g 997 -S pigpio \
    && adduser -S squeezelite \
    && addgroup squeezelite piaudio \
	&& addgroup squeezelite pigpio

# create file to be able to map host asound.conf
RUN touch /etc/asound.conf
# create file to be able to map host squeeze<n>.name
RUN mkdir /config && touch /config/squeeze.name

COPY --from=builder /usr/local/src/dest/usr/lib/* /usr/lib/	
COPY --from=builder /usr/local/src/squeezelite-master/squeezelite /usr/local/bin/squeezelite
#COPY --from=builder /usr/local/src/squeezelite-master/alsacap /usr/local/bin/alsacap
#COPY --from=builder /usr/local/src/squeezelite-master/find_servers /usr/local/bin/find_servers
COPY --from=builder /usr/lib/libwiringPi.so* /usr/lib/
COPY --from=builder /usr/local/src/gpio /usr/local/bin/gpio
COPY --from=builder /usr/lib/alsa-lib/libasound_module_pcm_equal.so /usr/lib/alsa-lib/libasound_module_pcm_equal.so
COPY --from=builder /usr/lib/alsa-lib/libasound_module_ctl_equal.so /usr/lib/alsa-lib/libasound_module_ctl_equal.so

COPY power_mute.sh /usr/local/bin/power_mute.sh
RUN chmod +x /usr/local/bin/power_mute.sh
COPY squeezelite.sh /usr/local/bin/squeezelite.sh
RUN chmod +x /usr/local/bin/squeezelite.sh

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "squeezelite.sh" ]