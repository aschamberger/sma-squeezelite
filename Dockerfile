FROM alpine:3.21.2 AS builder

#ARG ALSAEQUAL_VERSION=master
# use older commit to be compatible with version from raspberry pi OS
ARG ALSAEQUAL_VERSION=0e9c8c3ed426464609114b9402b71b4cc0edabc9
#ARG SQUEEZELITE_VERSION=master
ARG SQUEEZELITE_VERSION=bb78c1d3b057b4417e82a57041bda6f4acf116da

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache build-base alsa-lib-dev linux-headers

RUN mkdir -p /usr/local/src

RUN cd /usr/local/src \
    && wget https://github.com/raedwulf/alsaequal/archive/$ALSAEQUAL_VERSION.zip -O alsaequal.zip \
    && unzip alsaequal.zip \
    && cd alsaequal-$ALSAEQUAL_VERSION \
    && make \
    && mkdir -p /usr/lib/alsa-lib \
    && make install
    
RUN apk update \
    && apk add --no-cache wget unzip autoconf automake flac-dev faad2-dev mpg123-dev libvorbis-dev libmad-dev soxr-dev openssl-dev opusfile-dev opus-dev libogg-dev libtool

RUN cd /usr/local/src \
    && mkdir dest \
#    && wget https://github.com/ralph-irving/squeezelite/archive/$SQUEEZELITE_VERSION.zip -O squeezelite.zip \
    && wget https://github.com/aschamberger/squeezelite/archive/$SQUEEZELITE_VERSION.zip -O squeezelite.zip \
    && unzip squeezelite.zip \
    && wget https://github.com/TimothyGu/alac/archive/master.zip -O libalac.zip \
    && unzip libalac.zip \
    && wget https://gitlab.xiph.org/xiph/tremor/-/archive/master/tremor-master.zip -O libtremor.zip \
    && unzip libtremor.zip

COPY load-libtremor-first.patch /usr/local/src/squeezelite-$SQUEEZELITE_VERSION/alpine/load-libtremor-first.patch

RUN cd /usr/local/src \
    && cd alac-master \
    && patch -p1 -i ../squeezelite-$SQUEEZELITE_VERSION/alpine/libalac/fix-arm-segfault.patch \
    && patch -p1 -i ../squeezelite-$SQUEEZELITE_VERSION/alpine/libalac/alac-version.patch \
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
    && cd squeezelite-$SQUEEZELITE_VERSION \
    && patch -p1 -i alpine/load-libtremor-first.patch \
    && make OPTS="-DRESAMPLE -DDSD -DGPIO -DVISEXPORT -DUSE_SSL -DOPUS -DALAC -DLINE_IN -I/usr/include/opus -I/usr/include/alac" \
    && gcc -Os -fomit-frame-pointer -fcommon -s -o find_servers tools/find_servers.c \
    && gcc -Os -fomit-frame-pointer -fcommon -s -o alsacap tools/alsacap.c -lasound 
   
RUN apk update \
    && apk add --no-cache autoconf-archive libgudev libgudev-dev
        
RUN cd /usr/local/src \
    && wget https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/snapshot/libgpiod-2.2.tar.gz \
    && tar xvzf libgpiod-2.2.tar.gz \
    && cd libgpiod-2.2/ \
    && ./autogen.sh --enable-bindings-glib --enable-dbus --sysconfdir=/etc \
    && make \
    && make DESTDIR="/usr/local/src/dest" install

FROM alpine:3.21.2

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache tini su-exec flac alsa-lib faad2-libs mpg123-libs libvorbis libmad soxr openssl opusfile libogg curl jq flock alsa-utils libgudev

RUN apk add caps --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted

# add group piaudio and pigpio with gid of underlying raspberry os groups
RUN addgroup -g 29 -S piaudio \
    && addgroup -g 993 -S pigpio \
    && adduser -S squeezelite \
    && addgroup squeezelite piaudio \
	&& addgroup squeezelite pigpio

# create file to be able to map host asound.conf
RUN touch /etc/asound.conf
# create file to be able to map host squeeze<n>.name
RUN mkdir /config && touch /config/squeeze.name

COPY --from=builder /usr/local/src/dest/usr/lib/* /usr/lib/	
COPY --from=builder /usr/local/src/squeezelite-*/squeezelite /usr/local/bin/squeezelite
#COPY --from=builder /usr/local/src/squeezelite-*/alsacap /usr/local/bin/alsacap
#COPY --from=builder /usr/local/src/squeezelite-*/find_servers /usr/local/bin/find_servers
COPY --from=builder /usr/local/src/dest/usr/local/lib/* /usr/local/lib/	
COPY --from=builder /usr/local/src/dest/usr/local/bin/gpiocli /usr/local/bin/gpiocli
COPY --from=builder /usr/lib/alsa-lib/libasound_module_pcm_equal.so /usr/lib/alsa-lib/libasound_module_pcm_equal.so
COPY --from=builder /usr/lib/alsa-lib/libasound_module_ctl_equal.so /usr/lib/alsa-lib/libasound_module_ctl_equal.so

WORKDIR /usr/local/bin
COPY power_mute.sh power_mute.sh
RUN chmod +x power_mute.sh
COPY line_in.sh line_in.sh
RUN chmod +x line_in.sh
COPY squeezelite.sh squeezelite.sh
RUN chmod +x squeezelite.sh

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "squeezelite.sh" ]
