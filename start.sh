#!/bin/bash
chown dokku:dokku $DOKKU_ROOT

groupmod -g $DOCKER_GID docker

sudo -nE -u dokku bash -c '/usr/local/bin/prepare_dokku'

exec /usr/bin/supervisord
