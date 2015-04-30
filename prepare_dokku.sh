#!/bin/bash
echo "$(hostname)" > $DOKKU_ROOT/HOSTNAME
echo "$(hostname)" > $DOKKU_ROOT/VHOST
[[ -e $DOKKU_ROOT/.ssh/authorized_keys ]] || touch $DOKKU_ROOT/.ssh/authorized_keys
[[ -e $DOKKU_ROOT/.sshcommand ]] || /usr/local/bin/sshcommand create dokku `which dokku`

# rebuild all nginx.conf (only needed if hostname was changed)
dokku apps | tail -n +2 | xargs -n1 dokku nginx:build-config
