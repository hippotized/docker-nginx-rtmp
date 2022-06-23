ARG NGINX_VERSION=1.20.2
ARG NGINX_RTMP_VERSION=dev
ARG FFMPEG_VERSION=4.3.3
ARG BASE_IMAGE=alpine:3.15

##############################
# Build the NGINX-build image.
FROM ${BASE_IMAGE} as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION
ARG MAKEFLAGS="-j4"

# Build dependencies.
RUN apk add --no-cache \
  build-base \
  curl \
  linux-headers \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev

RUN \
# Get nginx source and nginx-rtmp module. \
  curl -sLRo - https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz -C /tmp/ && \
  curl -sLRo - https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/${NGINX_RTMP_VERSION}.tar.gz | tar xz -C /tmp/ && \
# Compile nginx with nginx-rtmp module. \
  export MAKEFLAGS="-j$(getconf _NPROCESSORS_ONLN)" && \
  cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-debug \
  --with-cc-opt="-Wimplicit-fallthrough=0 -Wdeprecated-declarations" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install && \
  rm -rf /var/cache/* /tmp/*

###############################
# Build the FFmpeg-build image.
FROM ${BASE_IMAGE} as build-ffmpeg
ARG FFMPEG_VERSION
ARG PREFIX=/usr/local

# FFmpeg build dependencies.
RUN apk add --no-cache \
  build-base \
  curl \
  freetype-dev \
  lame-dev \
  libogg-dev \
  libass \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  openssl-dev \
  opus-dev \
  rtmpdump-dev \
  x264-dev \
  x265-dev \
  yasm && \
apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community fdk-aac-dev

# Get FFmpeg source.
RUN curl -sLRo - https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | tar xz -C /tmp/ && \
# Compile ffmpeg. \
  export MAKEFLAGS="-j$(getconf _NPROCESSORS_ONLN)" && \
  cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --prefix=${PREFIX} \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-postproc \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" && \
  make && make install && make distclean && \
  rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM ${BASE_IMAGE}

# Set default ports.
ENV HTTP_PORT 80
ENV HTTPS_PORT 443
ENV RTMP_PORT 1935

RUN apk add --no-cache \
  ca-certificates \
  bash \
  curl \
  gettext \
  lame \
  libass \
  libogg \
  libtheora \
  libvorbis \
  libvpx \
  libwebp \
  openssl \
  opus \
  pcre \
  rtmpdump \
  x264-dev \
  x265-dev && \
  rm -rf /var/cache/* /tmp/*

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx
COPY --from=build-ffmpeg /usr/local /usr/local
COPY --from=build-ffmpeg /usr/lib/libfdk-aac.so.2 /usr/lib/libfdk-aac.so.2

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
COPY nginx.conf /etc/nginx/nginx.conf.template

RUN mkdir -p /opt/data && mkdir /www
COPY static /www/static

EXPOSE 1935
EXPOSE 80

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  nginx
