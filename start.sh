#!/bin/bash
set -xe

chown dokku:dokku $DOKKU_ROOT

getent group docker && groupmod -g $DOCKER_GID docker || groupadd -g $DOCKER_GID docker

usermod -a -G docker dokku

sudo -nE -u dokku bash -c '/usr/local/bin/prepare_dokku'

exec /usr/bin/supervisord
