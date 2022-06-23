#!/usr/bin/env bash
set -eu

docker run -it -p 1935:1935 -p 8080:80 --rm nginx-rtmp
