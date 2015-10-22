#!/bin/bash
set -e

cat /config/hostname > $DOKKU_ROOT/HOSTNAME
# Dokku, oh Dokku, i hate you really much.
cat /config/hostname > $DOKKU_ROOT/VHOST
echo ".protonet.info" > $DOKKU_ROOT/DOMAIN_SUFFIX


mkdir -p $DOKKU_ROOT/.ssh/ && chmod 700 $DOKKU_ROOT/.ssh/
echo "export PLUGIN_PATH=$PLUGIN_PATH" >> $DOKKU_ROOT/.ssh/environment

[[ -e $DOKKU_ROOT/.sshcommand ]] || /usr/local/bin/sshcommand create dokku `which dokku`

# this prevents old containers from remaining forever if system is rebooted during the default retirement delay
dokku config:set --global DOKKU_WAIT_TO_RETIRE=0

# this hopefully will prevent dokku from setting app-specific NO_VHOST to 1
dokku config:set --global NO_VHOST=0

# disable NO_VHOST for each app that got it
for i in $(dokku ls | tail -n+2 | awk '{print $1}'); do
	if [[ "$(dokku config:get $i NO_VHOST)" == "1" ]]; then
		dokku config:unset $i NO_VHOST
	fi
done

# redeploy running apps to update IP configuration
for i in $(dokku protonet:ls | awk '{ if($5=="started") print $1}'); do
	sudo -EHu dokku dokku deploy $i
done

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
dokku apps | tail -n +2 | xargs -n1 dokku domains:clear || true
