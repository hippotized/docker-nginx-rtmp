# docker-nginx-rtmp
A Dockerfile installing NGINX, nginx-rtmp-module and FFmpeg from source with
default settings for HLS live streaming. Built on Alpine Linux 3.15.

* Nginx 1.23.0 (Mainline version compiled from source)
* nginx-rtmp-module ([Sergey Dryabzhinsky's fork](https://github.com/sergey-dryabzhinsky/nginx-rtmp-module)) 1.2.x-dev (compiled from source)
* ffmpeg 5.0.1 (mwaders's ffmpeg static binary)
* Default HLS settings (See: [nginx.conf](nginx.conf))


## Usage

### Server
* Pull docker image and run:
```
docker pull alfg/nginx-rtmp
docker run -it -p 1935:1935 -p 8080:80 --rm alfg/nginx-rtmp
```
or 

* Build and run container from source:
```
docker build -t nginx-rtmp .
docker run -it -p 1935:1935 -p 8080:80 --rm nginx-rtmp
```

* Stream live content to:
```
rtmp://<server ip>:1935/input/$STREAM_NAME
```

### SSL 
To enable SSL, see [nginx.conf](nginx.conf) and uncomment the lines:
```
listen 443 ssl;
ssl_certificate     /opt/certs/example.com.crt;
ssl_certificate_key /opt/certs/example.com.key;
```

This will enable HTTPS using a self-signed certificate supplied in [/certs](/certs). If you wish to use HTTPS, it is **highly recommended** to obtain your own certificates and update the `ssl_certificate` and `ssl_certificate_key` paths.

I recommend using [Certbot](https://certbot.eff.org/docs/install.html) from [Let's Encrypt](https://letsencrypt.org).

### Environment Variables
This Docker image uses `envsubst` for environment variable substitution. You can define additional environment variables in `nginx.conf` as `${var}` and pass them in your `docker-compose` file or `docker` command.


### Custom `nginx.conf`
If you wish to use your own `nginx.conf`, mount it as a volume in your `docker-compose` or `docker` command as `nginx.conf.template`:
```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf.template
```

### OBS Configuration
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/input`
* Stream Key: `hello`

### Watch Stream
* Load up the example hls.js player in your browser:
```
http://localhost:8080/player.html?url=http://localhost:8080/live/hello.m3u8
```

* Or in Safari, VLC or any HLS player, open:
```
http://localhost:8080/live/$STREAM_NAME.m3u8
```
* Example Playlist: `http://localhost:8080/live/hello.m3u8`
* [HLS.js Player](https://hls-js.netlify.app/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`

### FFmpeg Build
```
$ ffmpeg -buildconf
ffmpeg version 5.0.1 Copyright (c) 2000-2022 the FFmpeg developers
  built with gcc 11.2.1 (Alpine 11.2.1_git20220219) 20220219
  configuration: --pkg-config-flags=--static --extra-cflags=-fopenmp --extra-ldflags='-fopenmp -Wl,-z,stack-size=2097152' --toolchain=hardened --disable-debug --disable-shared --disable-ffplay --enable-static --enable-gpl --enable-version3 --enable-nonfree --enable-fontconfig --enable-gray --enable-iconv --enable-libaom --enable-libass --enable-libbluray --enable-libdav1d --enable-libdavs2 --enable-libfdk-aac --enable-libfreetype --enable-libfribidi --enable-libgme --enable-libgsm --enable-libkvazaar --enable-libmodplug --enable-libmp3lame --enable-libmysofa --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-libopus --enable-librabbitmq --enable-librav1e --enable-librubberband --enable-libshine --enable-libsoxr --enable-libspeex --enable-libsrt --enable-libssh --enable-libsvtav1 --enable-libtheora --enable-libtwolame --enable-libuavs3d --enable-libvidstab --enable-libvmaf --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxavs2 --enable-libxml2 --enable-libxvid --enable-libzimg --enable-openssl
  libavutil      57. 17.100 / 57. 17.100
  libavcodec     59. 18.100 / 59. 18.100
  libavformat    59. 16.100 / 59. 16.100
  libavdevice    59.  4.100 / 59.  4.100
  libavfilter     8. 24.100 /  8. 24.100
  libswscale      6.  4.100 /  6.  4.100
  libswresample   4.  3.100 /  4.  3.100
  libpostproc    56.  3.100 / 56.  3.100

  configuration:
    --pkg-config-flags=--static
    --extra-cflags=-fopenmp
    --extra-ldflags='-fopenmp -Wl,-z,stack-size=2097152'
    --toolchain=hardened
    --disable-debug
    --disable-shared
    --disable-ffplay
    --enable-static
    --enable-gpl
    --enable-version3
    --enable-nonfree
    --enable-fontconfig
    --enable-gray
    --enable-iconv
    --enable-libaom
    --enable-libass
    --enable-libbluray
    --enable-libdav1d
    --enable-libdavs2
    --enable-libfdk-aac
    --enable-libfreetype
    --enable-libfribidi
    --enable-libgme
    --enable-libgsm
    --enable-libkvazaar
    --enable-libmodplug
    --enable-libmp3lame
    --enable-libmysofa
    --enable-libopencore-amrnb
    --enable-libopencore-amrwb
    --enable-libopenjpeg
    --enable-libopus
    --enable-librabbitmq
    --enable-librav1e
    --enable-librubberband
    --enable-libshine
    --enable-libsoxr
    --enable-libspeex
    --enable-libsrt
    --enable-libssh
    --enable-libsvtav1
    --enable-libtheora
    --enable-libtwolame
    --enable-libuavs3d
    --enable-libvidstab
    --enable-libvmaf
    --enable-libvorbis
    --enable-libvpx
    --enable-libwebp
    --enable-libx264
    --enable-libx265
    --enable-libxavs2
    --enable-libxml2
    --enable-libxvid
    --enable-libzimg
    --enable-openssl
```


### FFmpeg Hardware Acceleration
A `Dockerfile.cuda` image is available to enable FFmpeg hardware acceleration via the [NVIDIA's CUDA](https://trac.ffmpeg.org/wiki/HWAccelIntro#CUDANVENCNVDEC).

Use the tag: `alfg/nginx-rtmp:cuda`:
```
docker run -it -p 1935:1935 -p 8080:80 --rm alfg/nginx-rtmp:cuda
```

You must have a supported platform and driver to run this image.

* https://github.com/NVIDIA/nvidia-docker
* https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker
* https://docs.docker.com/docker-for-windows/wsl/
* https://trac.ffmpeg.org/wiki/HWAccelIntro#CUDANVENCNVDEC

**This image is experimental!*

## Resources
* https://alpinelinux.org
* https://nginx.org
* https://github.com/arut/nginx-rtmp-module
* https://www.ffmpeg.org
* https://obsproject.com
