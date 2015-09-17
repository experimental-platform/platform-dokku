#!/bin/bash
set -e

chown -R dokku:dokku $DOKKU_ROOT
getent group docker && groupmod -g $DOCKER_GID docker || groupadd -g $DOCKER_GID docker
usermod -a -G docker dokku
chmod 666 /var/run/docker.sock

sudo -nE -u dokku bash -c '/usr/local/bin/prepare_dokku'

exec /usr/bin/supervisord
