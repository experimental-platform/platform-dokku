#!/bin/bash
chown dokku:dokku $DOKKU_ROOT

usermod -G $DOCKER_GID dokku

sudo -nE -u dokku bash -c '/usr/local/bin/prepare_dokku'

exec /usr/bin/supervisord
