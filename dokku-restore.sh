#!/usr/bin/env bash

set -eo pipefail

CONTAINERS=$(docker ps -a -f status=running -f status=exited -q)

for i in $CONTAINERS; do
  POLICY="$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $i)"

  if [[ "$POLICY" == "on-failure" ]]; then
    docker rm -f $i || true
  fi;
done

sudo -EH -u dokku dokku cleanup || true
sudo -EH -u dokku dokku ps:restore || true

