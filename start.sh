#!/bin/bash
chown dokku:dokku $DOKKU_ROOT

groupmod -g $DOCKER_GID docker
usermod -a -G docker dokku

sudo -nE -u dokku bash -c '/usr/local/bin/prepare_dokku'

exec /usr/bin/supervisord
