#!/usr/bin/env bash

CONTAINERS=$(docker ps -a -f status=running -f status=exited -q)

for i in $CONTAINERS; do
  POLICY="$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $i)"

  if [[ "$POLICY" == "on-failure" ]]; then
    docker rm -f $i;
  fi;
done
