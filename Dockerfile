ARG NGINX_VERSION=1.23.0
ARG NGINX_RTMP_VERSION=dev
ARG FFMPEG_VERSION=5.0.1-3
ARG BASE_IMAGE=alpine:3.16

ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG LDFLAGS="-Wl,-z,relro,-z,now"


##############################
# Build the NGINX-build image.
FROM ${BASE_IMAGE} as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apk add --no-cache \
  build-base \
  curl \
  linux-headers \
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
  --with-cc-opt="-Wimplicit-fallthrough=0 -Wdeprecated-declarations" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install && \
  rm -rf /var/cache/* /tmp/*

###############################
# Build the FFmpeg-build image.
FROM mwader/static-ffmpeg:${FFMPEG_VERSION} as build-ffmpeg

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
  openssl \
  pcre \
  rtmpdump \
  && \
  rm -rf /var/cache/* /tmp/*

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx
COPY --from=build-ffmpeg /ffmpeg /usr/local/bin/

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
COPY nginx.conf /etc/nginx/nginx.conf.template

RUN mkdir -p /opt/data && mkdir /www
COPY static /www/static

EXPOSE 1935
EXPOSE 80

RUN nginx -V >&2
RUN ffmpeg -version >&2

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  nginx
