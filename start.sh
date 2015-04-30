#!/bin/bash
chown dokku:dokku $DOKKU_ROOT

sudo -nE -u dokku bash -c '/usr/local/bin/prepare_dokku'

exec /usr/bin/supervisord
