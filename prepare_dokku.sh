#!/bin/bash
cat /config/hostname > $DOKKU_ROOT/HOSTNAME
echo ".protonet.info" > $DOKKU_ROOT/DOMAIN_SUFFIX

[[ -e $DOKKU_ROOT/.sshcommand ]] || /usr/local/bin/sshcommand create dokku `which dokku`

echo -n "" > $DOKKU_ROOT/.ssh/authorized_keys
for KEYFILE in /config/ssh/*
do
  if [[ -f $KEYFILE ]]; then
    FINGERPRINT=$(ssh-keygen -lf $KEYFILE | cut -d \  -f 2)
    KEY=$(cat $KEYFILE)
    echo "command=\"FINGERPRINT=$FINGERPRINT NAME=$KEYFILE \`cat $DOKKU_ROOT/.sshcommand\` \$SSH_ORIGINAL_COMMAND\",no-agent-forwarding,no-user-rc,no-X11-forwarding,no-port-forwarding $KEY" >> $DOKKU_ROOT/.ssh/authorized_keys
  fi
done
# rebuild all nginx.conf (only needed if hostname was changed)
# Strange but we need 'dokku domains:clear' here o.O
dokku apps | tail -n +2 | xargs -n1 dokku domains:clear
