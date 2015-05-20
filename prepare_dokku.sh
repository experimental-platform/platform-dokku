#!/bin/bash
echo $HOST_HOSTNAME > $DOKKU_ROOT/HOSTNAME
cat /config/nodename > $DOKKU_ROOT/VHOST
[[ -e $DOKKU_ROOT/.ssh/authorized_keys ]] || touch $DOKKU_ROOT/.ssh/authorized_keys
[[ -e $DOKKU_ROOT/.sshcommand ]] || /usr/local/bin/sshcommand create dokku `which dokku`

# rebuild all nginx.conf (only needed if hostname was changed)
# Strange but we need 'dokku domains:clear' here o.O
dokku apps | tail -n +2 | xargs -n1 dokku domains:clear
